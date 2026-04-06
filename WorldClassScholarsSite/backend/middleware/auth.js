const jwt = require('jsonwebtoken');
const config = require('../config/environment');

/**
 * Generate a JWT token
 * @param {object} payload - Data to encode in token
 * @param {string} expiresIn - Token expiration time (default: 1 hour)
 * @returns {string} - JWT token
 */
const generateToken = (payload, expiresIn = '1h') => {
  return jwt.sign(payload, config.security.jwtSecret, { expiresIn });
};

/**
 * Verify a JWT token
 * @param {string} token - Token to verify
 * @returns {object|null} - Decoded payload or null if invalid
 */
const verifyToken = (token) => {
  try {
    return jwt.verify(token, config.security.jwtSecret);
  } catch (error) {
    console.error('Token verification failed:', error.message);
    return null;
  }
};

/**
 * Middleware to authenticate requests using JWT
 */
const authMiddleware = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Missing authorization token' });
  }

  const decoded = verifyToken(token);
  if (!decoded) {
    return res.status(403).json({ error: 'Invalid or expired token' });
  }

  req.user = decoded;
  next();
};

module.exports = {
  generateToken,
  verifyToken,
  authMiddleware,
};
