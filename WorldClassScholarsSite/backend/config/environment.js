require('dotenv').config();

const config = {
  // Environment
  env: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || 3000),
  isDevelopment: process.env.NODE_ENV !== 'production',

  // OpenAI
  openai: {
    apiKey: process.env.OPENAI_API_KEY,
    model: 'dall-e-3',
  },

  // Security
  security: {
    encryptionKey: process.env.ENCRYPTION_KEY,
    jwtSecret: process.env.JWT_SECRET,
    allowedOrigins: (
      process.env.ALLOWED_ORIGINS || 'http://localhost:3000'
    ).split(','),
  },

  // Rate Limiting
  rateLimit: {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || 900000), // 15 minutes
    maxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || 100),
  },

  // Image Generation
  imageGeneration: {
    cacheTtl: parseInt(process.env.IMAGE_CACHE_TTL || 86400), // 24 hours
    maxRequestsPerUser: parseInt(
      process.env.MAX_IMAGE_GENERATION_REQUESTS || 5,
    ),
    quality: 'hd',
    size: '1024x1024',
  },

  // Logging
  logging: {
    level: process.env.LOG_LEVEL || 'info',
  },
};

// Validate critical configuration
const validateConfig = () => {
  const requiredKeys = ['OPENAI_API_KEY', 'ENCRYPTION_KEY', 'JWT_SECRET'];
  const missing = requiredKeys.filter((key) => !process.env[key]);

  if (missing.length > 0 && process.env.NODE_ENV === 'production') {
    throw new Error(
      `Missing required environment variables: ${missing.join(', ')}`,
    );
  }

  if (process.env.ENCRYPTION_KEY && process.env.ENCRYPTION_KEY.length < 32) {
    console.warn(
      '⚠️  Warning: ENCRYPTION_KEY should be at least 32 characters long',
    );
  }
};

validateConfig();

module.exports = config;
