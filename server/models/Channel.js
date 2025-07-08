const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Channel = sequelize.define('Channel', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false,
    validate: {
      len: [1, 50],
    },
  },
  description: {
    type: DataTypes.STRING,
    validate: {
      len: [0, 200],
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
  createdById: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id',
    },
  },
  isPrivate: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  lastMessageId: {
    type: DataTypes.UUID,
    references: {
      model: 'messages',
      key: 'id',
    },
  },
}, {
  tableName: 'channels',
  hooks: {
    beforeSave: (channel) => {
      // Ensure channel name starts with #
      if (!channel.name.startsWith('#')) {
        channel.name = '#' + channel.name;
      }
    },
  },
});

module.exports = Channel; 