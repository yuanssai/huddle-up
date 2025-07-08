const jwt = require('jsonwebtoken');
const { User } = require('../models');

const auth = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ error: 'Access denied. No token provided.' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback-secret');
    const user = await User.findByPk(decoded.id);
    
    if (!user) {
      return res.status(401).json({ error: 'Token is not valid.' });
    }

    req.user = user;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Token is not valid.' });
  }
};

const generateToken = (userId) => {
  return jwt.sign({ id: userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN
  });
};

module.exports = auth; 