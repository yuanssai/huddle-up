const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { 
  sendMessage, 
  editMessage, 
  deleteMessage, 
  addReaction 
} = require('../controllers/messageController');

// @route   POST /api/messages
// @desc    Send a message
// @access  Private
router.post('/', auth, sendMessage);

// @route   PUT /api/messages/:messageId
// @desc    Edit a message
// @access  Private
router.put('/:messageId', auth, editMessage);

// @route   DELETE /api/messages/:messageId
// @desc    Delete a message
// @access  Private
router.delete('/:messageId', auth, deleteMessage);

// @route   POST /api/messages/:messageId/reaction
// @desc    Add/remove reaction to message
// @access  Private
router.post('/:messageId/reaction', auth, addReaction);

module.exports = router; 