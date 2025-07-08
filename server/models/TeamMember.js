const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const TeamMember = sequelize.define('TeamMember', {
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
  teamId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'teams',
      key: 'id',
    },
  },
  role: {
    type: DataTypes.ENUM('admin', 'member'),
    defaultValue: 'member',
  },
  joinedAt: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
}, {
  tableName: 'team_members',
  indexes: [
    {
      unique: true,
      fields: ['user_id', 'team_id'],
    },
  ],
});

module.exports = TeamMember; 