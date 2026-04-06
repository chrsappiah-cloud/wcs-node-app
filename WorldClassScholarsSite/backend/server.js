const helmet = require('helmet');
const cors = require('cors');
const express = require('express');
const config = require('./config/environment');
const { generateToken } = require('./middleware/auth');
const { apiLimiter } = require('./middleware/rateLimiter');
const imageRoutes = require('./routes/images');

// Initialize Express app
const app = express();

// ============================================
// Security Middleware
// ============================================

// Helmet: Set security HTTP headers
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", 'data:', 'https:'],
      connectSrc: ["'self'", 'https://api.openai.com'],
    },
  },
  hsts: {
    maxAge: 31536000, // 1 year in seconds
    includeSubDomains: true,
    preload: true,
  },
}));

// CORS: Restrict allowed origins
app.use(cors({
  origin: config.security.allowedOrigins,
  credentials: true,
  methods: ['GET', 'POST', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Body parser with size limits
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: false }));

// Rate limiting
app.use('/api/', apiLimiter);

// ============================================
// Request Logging Middleware
// ============================================
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.path} - ${res.statusCode} (${duration}ms)`);
  });
  next();
});

// ============================================
// Health Check Endpoint
// ============================================
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    environment: config.env,
  });
});

// ============================================
// Auth Endpoints
// ============================================

/**
 * Generate a demo token (for testing)
 * POST /api/auth/token
 */
app.post('/api/auth/token', (req, res) => {
  if (config.isDevelopment) {
    const token = generateToken({ id: 'demo-user', role: 'user' });
    return res.json({ token });
  }
  res.status(403).json({ error: 'Token generation only available in development' });
});

// ============================================
// API Routes
// ============================================
app.use('/api/images', imageRoutes);

// ============================================
// Error Handling
// ============================================

// 404 Handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not found',
    path: req.path,
    method: req.method,
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);

  const statusCode = err.status || 500;
  const message = config.isDevelopment ? err.message : 'Internal server error';

  res.status(statusCode).json({
    error: message,
    ...(config.isDevelopment && { stack: err.stack }),
  });
});

// ============================================
// Start Server
// ============================================
const PORT = config.port;

app.listen(PORT, () => {
  console.log(`\n🚀 World Class Scholars API Server`);
  console.log(`📍 Running on: http://localhost:${PORT}`);
  console.log(`🔒 Environment: ${config.env}`);
  console.log(`🛡️  Security: Helmet + CORS + Rate Limiting + JWT Auth`);
  console.log(`🔑 OpenAI Integration: ${config.openai.apiKey ? '✅ Configured' : '❌ Missing API Key'}`);
  console.log('');
});

module.exports = app;
