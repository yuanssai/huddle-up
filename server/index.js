const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const jwt = require('jsonwebtoken');
require('dotenv').config();

// Import database and models
const { sequelize, User, Message, Channel, ChannelMember } = require('./models');

// Import routes
const authRoutes = require('./routes/auth');
const teamRoutes = require('./routes/teams');
const channelRoutes = require('./routes/channels');
const messageRoutes = require('./routes/messages');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/teams', teamRoutes);
app.use('/api/channels', channelRoutes);
app.use('/api/messages', messageRoutes);

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'Huddle Up server is running' });
});

// Socket.IO authentication middleware
const authenticateSocket = async (socket, next) => {
  try {
    const token = socket.handshake.auth.token;
    if (!token) {
      return next(new Error('Authentication error'));
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback-secret');
    const user = await User.findByPk(decoded.id);
    
    if (!user) {
      return next(new Error('Authentication error'));
    }

    socket.user = user;
    next();
  } catch (error) {
    next(new Error('Authentication error'));
  }
};

// Apply authentication middleware to all socket connections
io.use(authenticateSocket);

// Socket.IO connection handling
io.on('connection', (socket) => {
  console.log(`User ${socket.user.username} connected`);

  // Update user online status
  User.update(
    { isOnline: true },
    { where: { id: socket.user.id } }
  );

  // Join user to their team rooms
  socket.on('join-teams', async (teamIds) => {
    try {
      for (const teamId of teamIds) {
        socket.join(`team-${teamId}`);
      }
      console.log(`User ${socket.user.username} joined teams: ${teamIds}`);
    } catch (error) {
      console.error('Error joining teams:', error);
    }
  });

  // Join channel
  socket.on('join-channel', async (channelId) => {
    try {
      const channelMember = await ChannelMember.findOne({
        where: {
          channelId: channelId,
          userId: socket.user.id
        }
      });

      if (channelMember) {
        socket.join(`channel-${channelId}`);
        console.log(`User ${socket.user.username} joined channel: ${channelId}`);
      }
    } catch (error) {
      console.error('Error joining channel:', error);
    }
  });

  // Leave channel
  socket.on('leave-channel', (channelId) => {
    socket.leave(`channel-${channelId}`);
    console.log(`User ${socket.user.username} left channel: ${channelId}`);
  });

  // Send message
  socket.on('send-message', async (data) => {
    try {
      const { content, channelId } = data;

      // Verify user can send message to this channel
      const channelMember = await ChannelMember.findOne({
        where: {
          channelId: channelId,
          userId: socket.user.id
        }
      });

      if (!channelMember) {
        socket.emit('error', { message: 'Access denied' });
        return;
      }

      const channel = await Channel.findByPk(channelId);
      
      // Create message
      const message = await Message.create({
        content,
        senderId: socket.user.id,
        channelId: channelId,
        teamId: channel.teamId
      });

      // Update channel's last message
      await Channel.update(
        { lastMessageId: message.id },
        { where: { id: channelId } }
      );

      const populatedMessage = await Message.findByPk(message.id, {
        include: [{
          model: User,
          as: 'sender',
          attributes: ['id', 'firstName', 'lastName', 'username', 'email']
        }]
      });

      // Emit to all users in the channel
      io.to(`channel-${channelId}`).emit('new-message', populatedMessage);

      console.log(`Message sent in channel ${channelId} by ${socket.user.username}`);
    } catch (error) {
      console.error('Error sending message:', error);
      socket.emit('error', { message: 'Failed to send message' });
    }
  });

  // Edit message
  socket.on('edit-message', async (data) => {
    try {
      const { messageId, content } = data;

      const message = await Message.findOne({
        where: {
          id: messageId,
          senderId: socket.user.id
        }
      });

      if (!message) {
        socket.emit('error', { message: 'Message not found' });
        return;
      }

      await message.update({
        content: content,
        editedAt: new Date()
      });

      const populatedMessage = await Message.findByPk(message.id, {
        include: [{
          model: User,
          as: 'sender',
          attributes: ['id', 'firstName', 'lastName', 'username', 'email']
        }]
      });

      // Emit to all users in the channel
      io.to(`channel-${message.channelId}`).emit('message-edited', populatedMessage);

      console.log(`Message edited by ${socket.user.username}`);
    } catch (error) {
      console.error('Error editing message:', error);
      socket.emit('error', { message: 'Failed to edit message' });
    }
  });

  // Delete message
  socket.on('delete-message', async (messageId) => {
    try {
      const message = await Message.findOne({
        where: {
          id: messageId,
          senderId: socket.user.id
        }
      });

      if (!message) {
        socket.emit('error', { message: 'Message not found' });
        return;
      }

      const channelId = message.channelId;
      await Message.destroy({ where: { id: messageId } });

      // Emit to all users in the channel
      io.to(`channel-${channelId}`).emit('message-deleted', messageId);

      console.log(`Message deleted by ${socket.user.username}`);
    } catch (error) {
      console.error('Error deleting message:', error);
      socket.emit('error', { message: 'Failed to delete message' });
    }
  });

  // User typing indicator
  socket.on('typing', (data) => {
    const { channelId, isTyping } = data;
    socket.to(`channel-${channelId}`).emit('user-typing', {
      userId: socket.user.id,
      username: socket.user.username,
      isTyping
    });
  });

  // Handle disconnect
  socket.on('disconnect', () => {
    console.log(`User ${socket.user.username} disconnected`);
    
    // Update user offline status
    User.update(
      { 
        isOnline: false,
        lastSeen: new Date()
      },
      { where: { id: socket.user.id } }
    );
  });
});

// Database connection and server startup
const startServer = async () => {
  try {
    // Test database connection
    await sequelize.authenticate();
    console.log('✅ Database connection established successfully.');

    // Start server
    const PORT = process.env.PORT || 3000;
    server.listen(PORT, () => {
      console.log(`🚀 Huddle Up server running on port ${PORT}`);
    });
  } catch (error) {
    console.error('❌ Unable to connect to database:', error);
    process.exit(1);
  }
};

startServer();

module.exports = app; 