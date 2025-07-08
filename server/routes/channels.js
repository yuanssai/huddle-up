const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { 
  createChannel, 
  getChannels, 
  getChannel, 
  joinChannel, 
  leaveChannel, 
  getChannelMessages 
} = require('../controllers/channelController');

// @route   POST /api/channels
// @desc    Create a new channel
// @access  Private
router.post('/', auth, createChannel);

// @route   GET /api/channels/team/:teamId
// @desc    Get channels for a team
// @access  Private
router.get('/team/:teamId', auth, getChannels);

// @route   GET /api/channels/:channelId
// @desc    Get channel by ID
// @access  Private
router.get('/:channelId', auth, getChannel);

// @route   POST /api/channels/:channelId/join
// @desc    Join channel
// @access  Private
router.post('/:channelId/join', auth, joinChannel);

// @route   DELETE /api/channels/:channelId/leave
// @desc    Leave channel
// @access  Private
router.delete('/:channelId/leave', auth, leaveChannel);

// @route   GET /api/channels/:channelId/messages
// @desc    Get channel messages
// @access  Private
router.get('/:channelId/messages', auth, getChannelMessages);

module.exports = router; 