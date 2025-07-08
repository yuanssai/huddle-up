const sequelize = require('../config/database');

// Import all models
const User = require('./User');
const Team = require('./Team');
const Channel = require('./Channel');
const Message = require('./Message');
const TeamMember = require('./TeamMember');
const ChannelMember = require('./ChannelMember');
const MessageReaction = require('./MessageReaction');

// Define associations

// User associations
User.hasMany(Team, { foreignKey: 'ownerId', as: 'ownedTeams' });
User.hasMany(Message, { foreignKey: 'senderId', as: 'messages' });
User.hasMany(Channel, { foreignKey: 'createdById', as: 'createdChannels' });

// Team associations
Team.belongsTo(User, { foreignKey: 'ownerId', as: 'owner' });
Team.hasMany(Channel, { foreignKey: 'teamId', as: 'channels' });
Team.hasMany(Message, { foreignKey: 'teamId', as: 'messages' });

// Channel associations
Channel.belongsTo(Team, { foreignKey: 'teamId', as: 'team' });
Channel.belongsTo(User, { foreignKey: 'createdById', as: 'createdBy' });
Channel.hasMany(Message, { foreignKey: 'channelId', as: 'messages' });
Channel.belongsTo(Message, { foreignKey: 'lastMessageId', as: 'lastMessage' });

// Message associations
Message.belongsTo(User, { foreignKey: 'senderId', as: 'sender' });
Message.belongsTo(Channel, { foreignKey: 'channelId', as: 'channel' });
Message.belongsTo(Team, { foreignKey: 'teamId', as: 'team' });
Message.belongsTo(Message, { foreignKey: 'parentMessageId', as: 'parentMessage' });
Message.hasMany(Message, { foreignKey: 'parentMessageId', as: 'replies' });

// Many-to-many associations through junction tables

// Users belong to many Teams through TeamMember
User.belongsToMany(Team, { 
  through: TeamMember, 
  foreignKey: 'userId', 
  otherKey: 'teamId',
  as: 'teams'
});
Team.belongsToMany(User, { 
  through: TeamMember, 
  foreignKey: 'teamId', 
  otherKey: 'userId',
  as: 'members'
});

// Users belong to many Channels through ChannelMember
User.belongsToMany(Channel, { 
  through: ChannelMember, 
  foreignKey: 'userId', 
  otherKey: 'channelId',
  as: 'channels'
});
Channel.belongsToMany(User, { 
  through: ChannelMember, 
  foreignKey: 'channelId', 
  otherKey: 'userId',
  as: 'members'
});

// Users react to many Messages through MessageReaction
User.belongsToMany(Message, { 
  through: MessageReaction, 
  foreignKey: 'userId', 
  otherKey: 'messageId',
  as: 'reactedMessages'
});
Message.belongsToMany(User, { 
  through: MessageReaction, 
  foreignKey: 'messageId', 
  otherKey: 'userId',
  as: 'reactedUsers'
});

// Direct associations for junction tables
TeamMember.belongsTo(User, { foreignKey: 'userId', as: 'user' });
TeamMember.belongsTo(Team, { foreignKey: 'teamId', as: 'team' });

ChannelMember.belongsTo(User, { foreignKey: 'userId', as: 'user' });
ChannelMember.belongsTo(Channel, { foreignKey: 'channelId', as: 'channel' });

MessageReaction.belongsTo(User, { foreignKey: 'userId', as: 'user' });
MessageReaction.belongsTo(Message, { foreignKey: 'messageId', as: 'message' });

// Export models
module.exports = {
  sequelize,
  User,
  Team,
  Channel,
  Message,
  TeamMember,
  ChannelMember,
  MessageReaction,
}; 