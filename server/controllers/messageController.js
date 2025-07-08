const { Message, Channel, User, ChannelMember, MessageReaction } = require('../models');

const sendMessage = async (req, res) => {
  try {
    const { content, channelId } = req.body;
    const userId = req.user.id;

    // Check if user is member of the channel
    const channelMember = await ChannelMember.findOne({
      where: {
        userId: userId,
        channelId: channelId
      }
    });

    if (!channelMember) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const channel = await Channel.findByPk(channelId);

    // Create message
    const message = await Message.create({
      content,
      senderId: userId,
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

    res.status(201).json({
      message: 'Message sent successfully',
      data: populatedMessage
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const editMessage = async (req, res) => {
  try {
    const { messageId } = req.params;
    const { content } = req.body;
    const userId = req.user.id;

    const message = await Message.findOne({
      where: {
        id: messageId,
        senderId: userId
      }
    });

    if (!message) {
      return res.status(404).json({ error: 'Message not found' });
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

    res.json({
      message: 'Message updated successfully',
      data: populatedMessage
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const deleteMessage = async (req, res) => {
  try {
    const { messageId } = req.params;
    const userId = req.user.id;

    const message = await Message.findOne({
      where: {
        id: messageId,
        senderId: userId
      }
    });

    if (!message) {
      return res.status(404).json({ error: 'Message not found' });
    }

    await Message.destroy({ where: { id: messageId } });

    res.json({ message: 'Message deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const addReaction = async (req, res) => {
  try {
    const { messageId } = req.params;
    const { emoji } = req.body;
    const userId = req.user.id;

    const message = await Message.findByPk(messageId);
    if (!message) {
      return res.status(404).json({ error: 'Message not found' });
    }

    // Check if user has access to this message
    const channelMember = await ChannelMember.findOne({
      where: {
        userId: userId,
        channelId: message.channelId
      }
    });

    if (!channelMember) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Check if reaction already exists
    const existingReaction = await MessageReaction.findOne({
      where: {
        userId: userId,
        messageId: messageId,
        emoji: emoji
      }
    });

    if (existingReaction) {
      // Remove reaction
      await MessageReaction.destroy({
        where: {
          userId: userId,
          messageId: messageId,
          emoji: emoji
        }
      });
    } else {
      // Add reaction
      await MessageReaction.create({
        userId: userId,
        messageId: messageId,
        emoji: emoji
      });
    }

    const populatedMessage = await Message.findByPk(messageId, {
      include: [
        {
          model: User,
          as: 'sender',
          attributes: ['id', 'firstName', 'lastName', 'username', 'email']
        },
        {
          model: User,
          as: 'reactedUsers',
          attributes: ['id', 'firstName', 'lastName', 'username'],
          through: {
            model: MessageReaction,
            attributes: ['emoji']
          }
        }
      ]
    });

    res.json({
      message: 'Reaction updated successfully',
      data: populatedMessage
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  sendMessage,
  editMessage,
  deleteMessage,
  addReaction
}; 