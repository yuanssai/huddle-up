const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const ChannelMember = sequelize.define('ChannelMember', {
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
  channelId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'channels',
      key: 'id',
    },
  },
  joinedAt: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
}, {
  tableName: 'channel_members',
  indexes: [
    {
      unique: true,
      fields: ['user_id', 'channel_id'],
    },
  ],
});

module.exports = ChannelMember; 