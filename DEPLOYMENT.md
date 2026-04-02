# GeoWCS Deployment Guide

## Overview

GeoWCS is deployed across three environments: Development, Staging, and Production. This guide covers the full deployment process.

---

## Development Environment

### Prerequisites

```bash
# macOS + Xcode 18+
xcode-select --install

# Node.js 18+
node --version

# Swift 5.9+
swift --version

# PostgreSQL 15
brew install postgresql@15

# Redis (for BullMQ)
brew install redis

# Git
git --version
```

### Local Setup

```bash
# Clone repo
git clone https://github.com/geowcs/geowcs.git
cd geowcs

# Install NestJS dependencies
cd dreamflow/apps/api
npm install

# Environment setup
cp .env.example .env.local
# Edit .env.local with your credentials:
# - TWILIO_ACCOUNT_SID
# - TWILIO_AUTH_TOKEN
# - JWT_SECRET
# - DATABASE_URL=postgresql://user:pass@localhost:5432/geowcs_dev
# - REDIS_URL=redis://localhost:6379

# Start PostgreSQL
brew services start postgresql@15

# Start Redis
brew services start redis

# Run migrations
npx prisma migrate dev --name init

# Start NestJS API
npm run start:dev
# Runs on http://localhost:3000

# Build iOS app
cd ../../..
xcodebuild build -project GeoWCS.xcodeproj -scheme GeoWCS -destination "platform=iOS Simulator,name=iPhone 17 Pro Max"

# Run simulator
xcrun simctl launch "iPhone 17 Pro Max" com.wcs.GeoWCS
```

### Testing

```bash
# NestJS tests
cd dreamflow/apps/api
npm test
# Expected: 20/20 pass ✓

# iOS build validation
xcodebuild build -project GeoWCS.xcodeproj -scheme GeoWCS
# Expected: BUILD SUCCEEDED
```

---

## Staging Deployment

### Prerequisites

- Azure subscription with resource group
- Azure CLI (`az`) installed
- Docker installed

### Deployment Steps

#### 1. Build Docker Image

```bash
cd dreamflow/apps/api

# Create Dockerfile
docker build -t geowcs-api:staging \
  --build-arg NODE_ENV=staging \
  .

# Test locally
docker run -p 3000:3000 \
  -e DATABASE_URL=postgresql://user:pass@host:5432/geowcs_staging \
  -e REDIS_URL=redis://host:6379 \
  geowcs-api:staging
```

#### 2. Push to Azure Container Registry

```bash
az login

# Create ACR
az acr create \
  --resource-group geowcs-staging \
  --name geowcsregistry \
  --sku Basic

# Login to ACR
az acr login --name geowcsregistry

# Tag image
docker tag geowcs-api:staging \
  geowcsregistry.azurecr.io/geowcs-api:staging

# Push image
docker push geowcsregistry.azurecr.io/geowcs-api:staging
```

#### 3. Deploy to Azure Container Instances

```bash
az container create \
  --resource-group geowcs-staging \
  --name geowcs-api \
  --image geowcsregistry.azurecr.io/geowcs-api:staging \
  --cpu 2 --memory 4 \
  --environment-variables \
    NODE_ENV=staging \
    DATABASE_URL=postgresql://... \
    REDIS_URL=... \
    JWT_SECRET=... \
  --ports 3000 \
  --protocol TCP

# Get URL
az container show \
  --resource-group geowcs-staging \
  --name geowcs-api \
  --query ipAddress.fqdn
# Output: geowcs-api.eastus.azurecontainer.io
```

#### 4. Configure DNS

```bash
# Point staging.api.geowcs.dev to ACI endpoint
# Via DNS provider (GoDaddy, AWS Route 53, etc.)
```

#### 5. iOS TestFlight Build

```bash
# Archive on macOS
xcodebuild archive \
  -project GeoWCS.xcodeproj \
  -scheme GeoWCS \
  -archivePath ./GeoWCS.xcarchive \
  -configuration Release

# Export IPA
xcodebuild -exportArchive \
  -archivePath ./GeoWCS.xcarchive \
  -exportOptionsPlist export.plist \
  -exportPath ./build

# Upload to TestFlight via Xcode
# - Product → Archive
# - Validate App
# - Upload to App Store

# Or via xcrun (Xcode 13+)
xcrun altool --upload-app \
  -f GeoWCS.ipa \
  -t ios \
  --apiKey $APP_STORE_CONNECT_KEY
```

#### 6. Staging Validation

```bash
# Test API
curl https://staging.api.geowcs.dev/v1/health

# Test iOS app on TestFlight (internal testers)
# - Invite beta testers in App Store Connect
# - Build automatically goes to TestFlight

# Smoke tests
# - Phone auth flow
# - Circle creation
# - Geofence alert submission
```

---

## Production Deployment

### Prerequisites

- Production Azure subscription
- App Store Connect account (Apple Developer Program)
- Managed PostgreSQL database (Azure Database for PostgreSQL)
- Managed Redis (Azure Cache for Redis)
- Secrets stored in Azure Key Vault

### Pre-Launch Checklist

- [ ] NestJS tests: 20/20 pass
- [ ] iOS build: BUILD SUCCEEDED
- [ ] APNs certificate provisioned
- [ ] Database backups configured
- [ ] Monitoring alerts set up
- [ ] Security audit completed
- [ ] GDPR compliance verified
- [ ] Terms of Service published
- [ ] Privacy Policy published

### Deployment Steps

#### 1. Prepare Infrastructure

```bash
# Use Bicep IaC templates
az deployment group create \
  --resource-group geowcs-prod \
  --template-file infrastructure/azure/main.bicep \
  --parameters infrastructure/azure/main.parameters.json

# This provisions:
# - App Service (for NestJS)
# - PostgreSQL Database (managed)
# - Redis Cache (managed)
# - Key Vault (secrets)
# - Application Insights (monitoring)
# - Azure CDN (optional, for assets)
```

#### 2. Configure Production Settings

```bash
# Azure Key Vault secrets
az keyvault secret set \
  --vault-name geowcs-prod \
  --name JWT-SECRET \
  --value $(openssl rand -base64 32)

az keyvault secret set \
  --vault-name geowcs-prod \
  --name DATABASE-URL \
  --value "postgresql://..."

az keyvault secret set \
  --vault-name geowcs-prod \
  --name REDIS-URL \
  --value "redis://..."

az keyvault secret set \
  --vault-name geowcs-prod \
  --name TWILIO-ACCOUNT-SID \
  --value "..."

# Assign Managed Identity to Key Vault
az keyvault set-policy \
  --name geowcs-prod \
  --object-id <app-service-managed-identity> \
  --secret-permissions get list
```

#### 3. Deploy NestJS API

```bash
# Build optimized Docker image
docker build \
  --build-arg NODE_ENV=production \
  -t geowcs-api:5.0.0 \
  dreamflow/apps/api

# Tag and push to ACR
docker tag geowcs-api:5.0.0 \
  geowcsregistry.azurecr.io/geowcs-api:5.0.0

docker push geowcsregistry.azurecr.io/geowcs-api:5.0.0

# Deploy to App Service
az webapp config container set \
  --name geowcs-api-prod \
  --resource-group geowcs-prod \
  --docker-custom-image-name geowcsregistry.azurecr.io/geowcs-api:5.0.0 \
  --docker-registry-server-url https://geowcsregistry.azurecr.io

# Set environment via Key Vault integration
az webapp config appsettings set \
  --name geowcs-api-prod \
  --resource-group geowcs-prod \
  --settings \
    NODE_ENV=production \
    "@Microsoft.KeyVault(SecretUri=https://geowcs-prod.vault.azure.net/secrets/JWT-SECRET/)" \
    "@Microsoft.KeyVault(SecretUri=https://geowcs-prod.vault.azure.net/secrets/DATABASE-URL/)"
```

#### 4. Database Migrations

```bash
# Connect to production database
export DATABASE_URL="postgresql://..."

# Run migrations (with backup first!)
npx prisma migrate deploy

# Seed if needed
npx prisma db seed
```

#### 5. Deploy iOS App

```bash
# Archive for App Store
xcodebuild archive \
  -project GeoWCS.xcodeproj \
  -scheme GeoWCS \
  -configuration Release \
  -archivePath ./GeoWCS-prod.xcarchive \
  -derivedDataPath ./build

# Export IPA with App Store certificate
xcodebuild -exportArchive \
  -archivePath ./GeoWCS-prod.xcarchive \
  -exportOptionsPlist export-appstore.plist \
  -exportPath ./build

# Validate
xcrun altool --validate-app \
  -f build/GeoWCS.ipa \
  -t ios \
  --apiKey $APP_STORE_CONNECT_KEY

# Submit to App Store
xcrun altool --upload-app \
  -f build/GeoWCS.ipa \
  -t ios \
  --apiKey $APP_STORE_CONNECT_KEY
```

#### 6. Verify Production Deployment

```bash
# API health
curl https://api.geowcs.dev/v1/health
# Expected: { "status": "ok" }

# Database connectivity
curl -H "Authorization: Bearer <token>" \
  https://api.geowcs.dev/v1/circles

# Monitoring in Azure
az monitor metrics list \
  --resource /subscriptions/.../geowcs-api-prod \
  --metric RequestCount
```

#### 7. Post-Launch

- Monitor error rates (Application Insights)
- Check APNs delivery success
- Verify CloudKit sync
- Monitor database performance
- Track user engagement

---

## Rollback Procedure

### If deployment fails:

```bash
# API rollback (to previous image)
az webapp config container set \
  --name geowcs-api-prod \
  --resource-group geowcs-prod \
  --docker-custom-image-name geowcsregistry.azurecr.io/geowcs-api:4.9.9

# iOS rollback (reject app in App Store Connect, or pull from store if already live)

# Database rollback
# 1. Restore from backup (at least hourly)
az sql db restore \
  --resource-group geowcs-prod \
  --server geowcs-db \
  --name geowcs_prod \
  --backup-creation 2026-04-02T15:00:00Z
```

---

## Monitoring & Maintenance

### Logs

```bash
# Stream API logs
az webapp log tail \
  --resource-group geowcs-prod \
  --name geowcs-api-prod

# Database slow query log
az postgres server show-logs \
  --ids /subscriptions/.../geowcs-db
```

### Alerts

Set up in Application Insights:
- Error rate > 5%
- Response time > 2s
- Database CPU > 80%
- Redis evictions > 0
- APNs delivery failures > 1%

### Backups

- **Database**: Automated daily, retain 35 days (Azure managed)
- **Code**: Git tags per release
- **Secrets**: Never backed up (recreate from source)

### Scaling

```bash
# Auto-scale App Service based on CPU
az appservice plan update \
  --name geowcs-plan-prod \
  --resource-group geowcs-prod \
  --sku P2V2

az autoscale create \
  --resource-group geowcs-prod \
  --resource geowcs-api-prod \
  --resource-type "Microsoft.Web/sites" \
  --min-count 2 \
  --max-count 10 \
  --count 2
```

---

## Cost Optimization

- Use spot instances for non-critical workloads
- Reserved instances for 1-year commitment
- Auto-shutdown for dev/staging environments
- CDN for static assets (logo, terms, privacy)

---

## Support

- Deployment issues: deployment@geowcs.dev
- Infrastructure: infra@geowcs.dev
- Slack: #deployment-alerts
