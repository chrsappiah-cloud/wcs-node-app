# Backend Setup & Deployment Guide

## Quick Start

### 1. Install Dependencies
```bash
cd WorldClassScholarsSite
npm install
```

### 2. Create Environment File
```bash
# Copy the template
cp .env.example .env

# Edit with your actual values
# Get OpenAI API key from: https://platform.openai.com/api-keys
nano .env
```

**Critical: Update these values in `.env`:**
```
OPENAI_API_KEY=sk_test_... # Your OpenAI key
ENCRYPTION_KEY=<generate-32-char-random-string>
JWT_SECRET=<generate-random-string>
NODE_ENV=development
```

### 3. Generate Secrets (One-time)
```bash
# Generate ENCRYPTION_KEY (32+ characters)
openssl rand -hex 16

# Generate JWT_SECRET (strong random)
openssl rand -base64 32
```

### 4. Start Development Server
```bash
npm run dev
```

Server runs on **http://localhost:3000**

## Testing the API

### 1. Get an Auth Token
```bash
curl -X POST http://localhost:3000/api/auth/token
```

Copy the token from the response.

### 2. Generate an Image
```bash
BEARER_TOKEN="<token-from-step-1>"

curl -X POST http://localhost:3000/api/images/generate \
  -H "Authorization: Bearer $BEARER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "A vibrant dinosaur with scales of gold and emerald green, standing in a misty forest at dawn",
    "style": "artistic",
    "quantity": 1
  }'
```

### 3. Check Health
```bash
curl http://localhost:3000/health
```

## Architecture Overview

```
WorldClassScholarsSite/
├── backend/
│   ├── config/
│   │   └── environment.js      # Configuration loader
│   ├── middleware/
│   │   ├── auth.js              # JWT authentication
│   │   ├── rateLimiter.js       # Rate limiting rules
│   │   └── validation.js        # Input validation
│   ├── routes/
│   │   └── images.js            # Image generation endpoints
│   ├── utils/
│   │   └── encryption.js        # AES-256 encryption
│   └── server.js                # Express app setup
├── .env                         # ⚠️  NEVER commit this!
├── .env.example                 # Template (commit this)
├── .gitignore                   # Git exclusions
├── package.json
└── index.html                   # Frontend
```

## Security Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **API Security** | Helmet.js | HTTP security headers |
| **CORS** | CORS middleware | Cross-origin protection |
| **Rate Limiting** | express-rate-limit | DDoS/brute-force prevention |
| **Authentication** | JWT | Secure token-based auth |
| **Input Validation** | express-validator | XSS/injection prevention |
| **Encryption** | Node.js Crypto (AES-256) | Sensitive data at rest |
| **Caching** | node-cache | Performance & cost reduction |

## Environment Variables Explained

**OPENAI_API_KEY**
- Get from: https://platform.openai.com/api-keys
- Format: `sk_live_...` or `sk_test_...`
- Required for image generation

**ENCRYPTION_KEY**
- Minimum 32 characters (ideally 64)
- Used for AES-256 encryption
- Generate: `openssl rand -hex 16`
- Keep secret! Never share.

**JWT_SECRET**
- Random secure string for token signing
- Minimum 32 characters recommended
- Generate: `openssl rand -base64 32`
- If changed, all issued tokens become invalid

**ALLOWED_ORIGINS**
- Comma-separated list of allowed domains
- Example: `http://localhost:3000,https://worldclassscholars.com`
- Default: `http://localhost:3000`

**RATE_LIMIT_WINDOW_MS**
- Time window for rate limiting in milliseconds
- Default: 900000 (15 minutes)
- Formula: `minutes * 60 * 1000`

**RATE_LIMIT_MAX_REQUESTS**
- Max API requests per window per IP
- Default: 100
- Prevents spam and abuse

**IMAGE_CACHE_TTL**
- Cache time-to-live in seconds
- Default: 86400 (24 hours)
- Saves API costs by avoiding duplicate requests

**MAX_IMAGE_GENERATION_REQUESTS**
- Max image generation per user per hour
- Default: 5
- Prevents excessive API usage

## Production Deployment

### Deploy to Heroku
```bash
# Create app
heroku create my-world-class-scholars

# Set environment variables
heroku config:set OPENAI_API_KEY=sk_...
heroku config:set ENCRYPTION_KEY=...
heroku config:set JWT_SECRET=...
heroku config:set NODE_ENV=production
heroku config:set ALLOWED_ORIGINS=https://worldclassscholars.com

# Deploy
git push heroku main
```

### Deploy to Azure
```bash
# Create App Service
az appservice plan create -g myResourceGroup -n myAppPlan --sku B1

az webapp create -g myResourceGroup -p myAppPlan -n my-wcs-api --runtime "NODE|18-lts"

# Set environment variables
az webapp config appsettings set -g myResourceGroup -n my-wcs-api \
  --settings OPENAI_API_KEY=sk_... ENCRYPTION_KEY=... JWT_SECRET=... NODE_ENV=production
```

### Deploy to DigitalOcean
```bash
# Create App Platform
doctl apps create --spec app.yaml

# App will auto-deploy on git push
```

## Monitoring & Debugging

### Enable Debug Logging
```bash
DEBUG=* npm run dev
```

### Check Rate Limiting
- Look for `X-RateLimit-Limit` header in responses
- Adjust `RATE_LIMIT_MAX_REQUESTS` if needed

### View Cache Stats
```bash
# Add to server.js route:
app.get('/api/cache/stats', (req, res) => {
  res.json(imageCache.getStats());
});
```

### Security Audit
```bash
npm audit
npm audit fix
```

## Troubleshooting

**"Missing required environment variables"**
- Ensure `.env` file exists
- Check all required keys are set
- Restart server after changes

**"OpenAI rate limit exceeded"**
- Increase cache TTL in `.env`
- Implement request queuing
- Contact OpenAI for higher limits

**"Too many requests"**
- Rate limiter is working correctly
- Increase `RATE_LIMIT_MAX_REQUESTS` if intentional
- Check for attack patterns in logs

**"Token verification failed"**
- Token may be expired (1-hour default)
- Get new token from `/api/auth/token`
- Check `JWT_SECRET` hasn't changed

## Next Steps

✅ **Completed:**
- ✅ Security middleware (Helmet, CORS, rate limiting)
- ✅ JWT authentication
- ✅ Input validation
- ✅ AES-256 encryption
- ✅ OpenAI image generation integration
- ✅ Image caching system

📋 **To Do:**
1. [ ] Install npm dependencies: `npm install`
2. [ ] Update `.env` with OpenAI API key
3. [ ] Start dev server: `npm run dev`
4. [ ] Test endpoints with curl
5. [ ] Integrate image gallery into frontend
6. [ ] Set up error logging (Sentry, LogRocket)
7. [ ] Configure monitoring (New Relic, DataDog)
8. [ ] Deploy to production

## Support
Questions? Email: Christopher.appiahthompson@myworldclass.org
