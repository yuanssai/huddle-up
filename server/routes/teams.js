const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { 
  createTeam, 
  getTeams, 
  getTeam, 
  joinTeam, 
  generateInviteCode, 
  leaveTeam 
} = require('../controllers/teamController');

// @route   POST /api/teams
// @desc    Create a new team
// @access  Private
router.post('/', auth, createTeam);

// @route   GET /api/teams
// @desc    Get user's teams
// @access  Private
router.get('/', auth, getTeams);

// @route   GET /api/teams/:teamId
// @desc    Get team by ID
// @access  Private
router.get('/:teamId', auth, getTeam);

// @route   POST /api/teams/join
// @desc    Join team by invite code
// @access  Private
router.post('/join', auth, joinTeam);

// @route   POST /api/teams/:teamId/invite
// @desc    Generate invite code
// @access  Private
router.post('/:teamId/invite', auth, generateInviteCode);

// @route   DELETE /api/teams/:teamId/leave
// @desc    Leave team
// @access  Private
router.delete('/:teamId/leave', auth, leaveTeam);

module.exports = router; 