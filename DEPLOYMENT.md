<!-- markdownlint-disable -->

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
env PATH="/usr/bin:/bin:/usr/sbin:/sbin:/Applications/Xcode.app/Contents/Developer/usr/bin" xcodebuild -exportArchive \
  -archivePath ./GeoWCS-prod.xcarchive \
  -exportOptionsPlist export-appstore.plist \
  -exportPath ./build \
  -allowProvisioningUpdates

# NOTE:
# The PATH prefix above avoids rsync client/server mismatches that can cause
# xcodebuild export failures such as "error: exportArchive Copy failed".

# Required App Store Connect auth values
export APP_STORE_CONNECT_KEY="<KEY_ID>"
export APP_STORE_CONNECT_ISSUER="<ISSUER_ID>"

# Validate
xcrun altool --validate-app \
  -f build/GeoWCS.ipa \
  -t ios \
  --apiKey $APP_STORE_CONNECT_KEY \
  --apiIssuer $APP_STORE_CONNECT_ISSUER

# Submit to App Store
xcrun altool --upload-app \
  -f build/GeoWCS.ipa \
  -t ios \
  --apiKey $APP_STORE_CONNECT_KEY \
  --apiIssuer $APP_STORE_CONNECT_ISSUER
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

---

## App Store Review Notes (Ready to Paste)

Use the text below in App Store Connect for the build uploaded on 2026-04-03.

### Notes for App Review

GeoWCS helps trusted contacts share live location, manage circles, and receive safety alerts.

Core flows to test:

1. Sign in with phone verification.
2. Create or join a circle.
3. Open live map and verify member location updates.
4. Configure geofence or safety alerts.

### Demo Account / Access

No preconfigured account is required. Reviewer can create a new account using phone verification during review.

If additional verification support is needed during review, contact: deployment@geowcs.dev

### Hardware and Permissions Required

GeoWCS requires these iOS permissions for core safety functionality:

- Location: Always or While Using the App
- Notifications: Allowed
- Cellular/Wi-Fi data access

If location or notifications are denied, certain features (live tracking, geofence alerts, and safety notifications) are limited by design.

### Content and Compliance Notes

- No hidden or locked features are required for review.
- The app does not require external hardware.
- Any emergency or safety messaging is informational and not a substitute for emergency services.

### Reviewer Quick Path

1. Install build from TestFlight.
2. Complete phone sign-in.
3. Create a circle and open the map.
4. Enable location + notifications when prompted.
5. Trigger a location update and verify circle visibility.

---

## App Store Listing Copy (Ready to Paste)

Use this text in App Store Connect for the current GeoWCS release.

### App Name

GeoWCS

### Subtitle (30 chars max)

Safety Circles and Live Map

### Promotional Text (170 chars max)

Stay connected with trusted contacts using live location, check-ins, geofence alerts, SOS, and private on-device audio evidence capture when safety matters most.

### Keywords (100 chars max)

safety,location,tracking,geofence,sos,checkin,family,friends,alerts,emergency,map,security

### Description

GeoWCS helps you stay safer with trusted contacts in real time.

Create a private safety circle, share location when you choose, and get alerts when people arrive or leave key places. In urgent moments, use SOS and capture audio evidence directly on your device.

Key features:
- Real-time location sharing with trusted circles
- Geofence arrival and departure alerts
- One-tap check-ins for daily safety routines
- SOS alerts with location context
- Private on-device audio recording and playback
- Smart notifications for circle and safety activity

Built with privacy in mind:
- You control who can see your location
- Location sharing can be turned on/off
- Audio recordings stay on device by default

Premium includes:
- Live map with friend overlays
- Unlimited circles
- Unlimited geofences

Whether you are commuting, meeting up, traveling, or checking on family, GeoWCS keeps trusted people connected when it matters most.

### What's New in This Version

- Initial public release of GeoWCS.
- Real-time trusted-circle location sharing.
- Geofence alerts for arrivals and departures.
- SOS safety alert flow.
- One-tap check-ins and smart safety notifications.
- On-device audio evidence recording and playback.
- Performance and reliability improvements for map and alert flows.

### Support URL

https://geowcs.dev/support

### Marketing URL (optional)

https://geowcs.dev

### Privacy Policy URL

https://geowcs.dev/privacy

---

## App Store Connect Submission Runbook (Final Step)

Use this checklist after pasting the Final Recommended listing copy.

### 1. Build Selection

- Open App Store Connect -> My Apps -> GeoWCS -> App Store -> iOS App
- In Build section, select the processed build uploaded on 2026-04-03
- Confirm version/build mapping is correct before saving

### 2. App Information

- Category: choose the most accurate primary category for personal safety/location coordination
- Content Rights: confirm rights to all content/assets
- Age Rating: complete all required questionnaire items

### 3. App Privacy

- Open App Privacy and ensure data collection answers match actual app behavior
- Ensure privacy labels are consistent with location, notifications, account, and optional audio features

### 4. Review Information

- Paste review notes from the section above
- Contact email: deployment@geowcs.dev
- Add contact phone if requested in your organization process
- If reviewer sign-in is needed, confirm self-signup via phone verification is acceptable

### 5. Version Release Option

- Choose one:
  - Manual release (recommended for first launch control)
  - Automatic release after approval
  - Scheduled release (set date/time)

### 6. Submit for Review

- Click Add for Review (if shown)
- Resolve any blocking warnings
- Click Submit for Review

### 7. Post-Submission Monitoring

- Track status: Waiting For Review -> In Review -> Pending Developer Release/Ready for Sale
- If Apple requests clarification, respond in Resolution Center with concise, factual answers

---

## App Store Listing Copy (Variant B - Conversion Focus)

Use this alternative if you want a more direct, everyday-safety tone.

### App Name

GeoWCS

### Subtitle (30 chars max)

Trusted Safety Circles

### Promotional Text (170 chars max)

Know your people are okay with live location, quick check-ins, geofence alerts, SOS, and private audio capture for important moments.

### Keywords (100 chars max)

safety app,live location,sos,check in,geofence,family safety,friend tracker,emergency,alerts,privacy

### Description

Feel safer together with GeoWCS.

GeoWCS helps you stay connected to the people you trust most. Create a private circle, share live location on your terms, and get alerts when someone arrives or leaves important places.

When things feel wrong, use SOS to quickly notify your circle. You can also capture audio evidence on-device for personal safety records.

What you can do with GeoWCS:
- Share location with trusted contacts in real time
- Receive arrival and departure geofence alerts
- Send one-tap check-ins and SOS alerts
- Get smart safety notifications
- Record and replay private audio evidence

Privacy first:
- You choose when location sharing is active
- You choose who sees your updates
- Audio stays on your device by default

Premium unlocks:
- Live map overlays for circle members
- Unlimited circles
- Unlimited geofences

Whether it is a late commute, a solo trip, or daily family coordination, GeoWCS helps your trusted people stay informed and connected.

### What's New in This Version

- First public release of GeoWCS.
- Trusted-circle live location sharing.
- Geofence arrival/departure alerts.
- SOS alert flow with location context.
- Fast check-ins and smart notifications.
- On-device audio evidence recording.
- Stability and performance improvements.

---

## App Store Listing Copy (Variant C - Review Conservative)

Use this option for a more neutral, policy-friendly App Store tone.

### App Name

GeoWCS

### Subtitle (30 chars max)

Location Sharing for Circles

### Promotional Text (170 chars max)

Coordinate with trusted contacts using location sharing, check-ins, geofence alerts, and optional on-device audio recording.

### Keywords (100 chars max)

location sharing,check in,geofence,contacts,circles,alerts,map,safety,privacy,family

### Description

GeoWCS is a coordination app for trusted contacts.

Create a circle, share your location when enabled, and receive notifications for arrivals, departures, and check-ins. The app also provides an SOS alert flow and optional on-device audio recording.

Main capabilities:
- Location sharing with selected contacts
- Geofence arrival and departure notifications
- Manual check-ins
- SOS alert to circle members
- On-device audio recording and playback

Privacy and controls:
- Location sharing is user controlled
- Access is limited to selected contacts
- Audio recordings are stored on device by default

Subscription options:
- Free tier includes core check-ins, alerts, and recording
- Premium includes live map overlays and expanded circle limits

GeoWCS is intended for personal coordination and awareness. It is not an emergency response service.

### What's New in This Version

- Initial App Store release.
- Circle-based location sharing.
- Geofence notifications.
- SOS alert flow.
- Check-ins and push notifications.
- On-device audio recording.

---

## App Store Listing Copy (Final Recommended)

Use this as the default submission copy.

### App Name

GeoWCS

### Subtitle (30 chars max)

Trusted Safety Circles

### Promotional Text (170 chars max)

Coordinate with trusted contacts using live location, check-ins, geofence alerts, SOS, and optional on-device audio recording.

### Keywords (100 chars max)

safety,location sharing,check in,geofence,sos,alerts,family,friends,privacy,map,contacts

### Description

GeoWCS helps trusted contacts stay connected with real-time awareness.

Create a private circle, share location when enabled, and receive arrival or departure notifications for important places. Send quick check-ins, trigger SOS alerts to your circle, and optionally capture audio evidence on-device.

Core features:
- Circle-based location sharing
- Geofence arrival and departure alerts
- One-tap check-ins
- SOS alerts to trusted contacts
- On-device audio recording and playback

Privacy and control:
- You control when location sharing is active
- You choose who can view your updates
- Audio recordings stay on your device by default

Premium includes:
- Live map overlays
- Unlimited circles
- Unlimited geofences

GeoWCS is intended for personal safety coordination and awareness. It is not an emergency response service.

### What's New in This Version

- Initial public release of GeoWCS.
- Real-time location sharing with trusted circles.
- Geofence arrival and departure alerts.
- SOS safety alert flow.
- One-tap check-ins and smart notifications.
- On-device audio evidence recording and playback.
- Stability and performance improvements.

### Support URL

https://geowcs.dev/support

### Marketing URL (optional)

https://geowcs.dev

### Privacy Policy URL

https://geowcs.dev/privacy
