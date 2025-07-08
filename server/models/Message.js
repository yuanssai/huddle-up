const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Message = sequelize.define('Message', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  content: {
    type: DataTypes.TEXT,
    allowNull: false,
    validate: {
      len: [1, 4000],
    },
  },
  senderId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id',
    },
  },
  channelId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'channels',
      key: 'id',
    },
  },
  teamId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'teams',
      key: 'id',
    },
  },
  messageType: {
    type: DataTypes.ENUM('text', 'file', 'image', 'system'),
    defaultValue: 'text',
  },
  fileUrl: {
    type: DataTypes.STRING,
  },
  editedAt: {
    type: DataTypes.DATE,
  },
  parentMessageId: {
    type: DataTypes.UUID,
    references: {
      model: 'messages',
      key: 'id',
    },
  },
}, {
  tableName: 'messages',
});

module.exports = Message; 