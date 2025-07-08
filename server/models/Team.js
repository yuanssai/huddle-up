const { DataTypes } = require('sequelize');
const { v4: uuidv4 } = require('uuid');
const sequelize = require('../config/database');

const Team = sequelize.define('Team', {
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
  ownerId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id',
    },
  },
  inviteCode: {
    type: DataTypes.STRING,
    unique: true,
  },
  isPublic: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
}, {
  tableName: 'teams',
});

// Instance method to generate invite code
Team.prototype.generateInviteCode = function() {
  this.inviteCode = uuidv4();
  return this.inviteCode;
};

module.exports = Team; 