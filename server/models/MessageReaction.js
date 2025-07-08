const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const MessageReaction = sequelize.define('MessageReaction', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  userId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id',
    },
  },
  messageId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'messages',
      key: 'id',
    },
  },
  emoji: {
    type: DataTypes.STRING,
    allowNull: false,
  },
}, {
  tableName: 'message_reactions',
  indexes: [
    {
      unique: true,
      fields: ['user_id', 'message_id', 'emoji'],
    },
  ],
});

module.exports = MessageReaction; 