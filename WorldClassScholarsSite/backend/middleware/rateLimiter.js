const rateLimit = require('express-rate-limit');
const config = require('../config/environment');

/**
 * General API rate limiter
 */
const apiLimiter = rateLimit({
  windowMs: config.rateLimit.windowMs,
  max: config.rateLimit.maxRequests,
  message: 'Too many requests, please try again later',
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => config.isDevelopment, // Skip rate limiting in development
});

/**
 * Stricter rate limiter for image generation
 */
const imageGenerationLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: config.imageGeneration.maxRequestsPerUser,
  message: 'Too many image generation requests. Please try again later.',
  keyGenerator: (req) => req.user?.id || req.ip, // Rate limit by user ID or IP
  skip: (req) => config.isDevelopment,
});

module.exports = {
  apiLimiter,
  imageGenerationLimiter,
};
