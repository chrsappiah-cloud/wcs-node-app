# World Class Scholars API - Security Documentation

## Overview
This is a production-hardened Node.js backend for World Class Scholars with OpenAI image generation integration.

## Security Features

### 1. **API Key Management**
- All sensitive data encrypted using AES-256-CBC
- Environment variables managed via `.env` file (never committed to git)
- Secure token generation for authentication

### 2. **HTTP Security Headers (Helmet)**
- Content Security Policy (CSP)
- X-Frame-Options (Clickjacking protection)
- X-Content-Type-Options (MIME type sniffing prevention)
- HSTS (Strict Transport Security)

### 3. **Rate Limiting**
- General API limiter: 100 requests per 15 minutes
- Image generation limiter: 5 requests per hour per user
- Per-IP rate limiting to prevent spam

### 4. **CORS Protection**
- Whitelisted origins only
- Credential-based requests enabled
- Restricted HTTP methods

### 5. **Authentication**
- JWT (JSON Web Tokens) for API authentication
- Token expiration (1 hour default)
- Secure token verification on protected routes

### 6. **Input Validation**
- Express-validator for request validation
- XSS prevention via escaping
- Length and format validation
- SQL injection prevention (no direct DB queries)

### 7. **Image Caching**
- 24-hour cache for generated images
- Reduces API calls and costs
- In-memory cache with TTL

## Setup

### 1. Install Dependencies
```bash
cd WorldClassScholarsSite/backend
npm install
```

### 2. Configure Environment
```bash
# Copy template
cp ../.env.example .env

# Edit .env with your values
nano .env
```

**Required Values:**
- `OPENAI_API_KEY` - Get from https://platform.openai.com/api-keys
- `ENCRYPTION_KEY` - Minimum 32 characters (use: `openssl rand -hex 16`)
- `JWT_SECRET` - Secure random string (use: `openssl rand -base64 32`)

### 3. Run Server

**Development:**
```bash
npm run dev
```

**Production:**
```bash
npm start
```

## API Endpoints

### Health Check
```bash
GET /health
```

### Get Auth Token (Development Only)
```bash
POST /api/auth/token
```
Returns: `{ "token": "eyJhbGc..." }`

### Generate Images
```bash
POST /api/images/generate
Authorization: Bearer <token>
Content-Type: application/json

{
  "prompt": "A beautiful dinosaur in the sunset",
  "style": "realistic",  // or: artistic, cartoon, sketch
  "quantity": 1  // 1-4
}
```

**Response:**
```json
{
  "success": true,
  "message": "Images generated successfully",
  "images": [
    {
      "url": "https://...",
      "alt": "A beautiful dinosaur in the sunset",
      "generated_at": "2026-04-07T12:00:00Z"
    }
  ],
  "cached": false
}
```

### Get Cached Image
```bash
GET /api/images/cache/:key
Authorization: Bearer <token>
```

## Environment Variables Reference

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `NODE_ENV` | string | development | Environment mode (development/production) |
| `PORT` | number | 3000 | Server port |
| `OPENAI_API_KEY` | string | required | OpenAI API key |
| `ENCRYPTION_KEY` | string | required | 32+ char encryption key |
| `JWT_SECRET` | string | required | JWT signing secret |
| `ALLOWED_ORIGINS` | string | localhost:3000 | CORS whitelist (comma-separated) |
| `RATE_LIMIT_WINDOW_MS` | number | 900000 | Rate limit window (15 min) |
| `RATE_LIMIT_MAX_REQUESTS` | number | 100 | Max requests per window |
| `IMAGE_CACHE_TTL` | number | 86400 | Cache TTL in seconds (24 hrs) |
| `MAX_IMAGE_GENERATION_REQUESTS` | number | 5 | Max generation requests/hour |

## Security Best Practices

✅ **DO:**
- Keep `.env` file confidential (never commit to git)
- Rotate API keys regularly
- Use HTTPS in production
- Monitor rate limiting and API usage
- Lock down CORS to specific origins
- Use strong encryption keys (32+ characters)
- Enable HSTS in production
- Validate all user inputs
- Log security-relevant events
- Keep dependencies updated (`npm audit fix`)

❌ **DON'T:**
- Commit `.env` to git
- Log API keys or tokens
- Disable CORS validation
- Use default/weak secrets
- Accept arbitrary user input
- Expose stack traces in production
- Use unencrypted connections
- Make API keys public
- Skip rate limiting
- Use old/vulnerable dependencies

## Testing

Get a demo token:
```bash
curl -X POST http://localhost:3000/api/auth/token
```

Generate an image:
```bash
curl -X POST http://localhost:3000/api/images/generate \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A colorful dinosaur with glowing eyes",
    "style": "artistic",
    "quantity": 1
  }'
```

## Production Deployment

### Recommended Platforms
- **Heroku** - Easy deployment with environment variables
- **AWS EC2** - Full control, scalable
- **Azure App Service** - Enterprise-grade
- **DigitalOcean** - Simple VPS option

### Pre-deployment Checklist
- [ ] Set `NODE_ENV=production`
- [ ] Use strong, unique environment variables
- [ ] Enable HTTPS/TLS
- [ ] Set up monitoring and logging
- [ ] Configure firewall rules
- [ ] Enable automatic backups
- [ ] Test all API endpoints
- [ ] Review security headers
- [ ] Plan rate limiting strategy
- [ ] Set up error alerting

## Support
For security issues, contact: Christopher.appiahthompson@myworldclass.org
