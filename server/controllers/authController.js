const { User, Team } = require('../models');
const jwt = require('jsonwebtoken');

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET || 'fallback-secret', {
    expiresIn: process.env.JWT_EXPIRES_IN || '24h'
  });
};

const register = async (req, res) => {
  try {
    const { email, username, password, firstName, lastName } = req.body;

    // Check if user already exists
    const existingUser = await User.findOne({ 
      where: {
        [require('sequelize').Op.or]: [
          { email },
          { username }
        ]
      }
    });
    
    if (existingUser) {
      return res.status(400).json({ 
        error: 'User with this email or username already exists' 
      });
    }

    // Create new user
    const user = await User.create({
      email,
      username,
      password,
      firstName,
      lastName
    });

    // Generate token
    const token = generateToken(user.id);

    res.status(201).json({
      message: 'User registered successfully',
      token,
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
        firstName: user.firstName,
        lastName: user.lastName
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user by email
    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(400).json({ error: 'Invalid credentials' });
    }

    // Check password
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(400).json({ error: 'Invalid credentials' });
    }

    // Update online status
    await user.update({ isOnline: true });

    // Generate token
    const token = generateToken(user.id);

    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
        firstName: user.firstName,
        lastName: user.lastName
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const getMe = async (req, res) => {
  try {
    const user = await User.findByPk(req.user.id, {
      include: [
        {
          model: Team,
          as: 'teams',
          through: { attributes: ['role', 'joinedAt'] }
        }
      ]
    });
    res.json(user);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const updateProfile = async (req, res) => {
  try {
    const { firstName, lastName, username } = req.body;
    
    const user = await User.findByPk(req.user.id);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    await user.update({
      firstName: firstName || user.firstName,
      lastName: lastName || user.lastName,
      username: username || user.username
    });

    res.json(user);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const logout = async (req, res) => {
  try {
    await User.update(
      { 
        isOnline: false,
        lastSeen: new Date()
      },
      { where: { id: req.user.id } }
    );
    res.json({ message: 'Logout successful' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  register,
  login,
  getMe,
  updateProfile,
  logout
}; 