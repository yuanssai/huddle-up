const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { register, login, getMe, updateProfile, logout } = require('../controllers/authController');

// @route   POST /api/auth/register
// @desc    Register a new user
// @access  Public
router.post('/register', register);

// @route   POST /api/auth/login
// @desc    Login user
// @access  Public
router.post('/login', login);

// @route   GET /api/auth/me
// @desc    Get current user
// @access  Private
router.get('/me', auth, getMe);

// @route   PUT /api/auth/profile
// @desc    Update user profile
// @access  Private
router.put('/profile', auth, updateProfile);

// @route   POST /api/auth/logout
// @desc    Logout user
// @access  Private
router.post('/logout', auth, logout);

module.exports = router; 