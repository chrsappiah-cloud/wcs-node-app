# GeoWCS Architecture

## System Overview

GeoWCS is a full-stack safety platform combining real-time location tracking, geofence-based alerts, and evidence capture with a modern tech stack:

```
┌─────────────────────────────────────────────────────────────┐
│                     iOS Swift Frontend                      │
│  (MapKit • CloudKit • AVFoundation • StoreKit 2)            │
├─────────────────────────────────────────────────────────────┤
│                    NestJS REST API                          │
│     (JWT Auth • BullMQ • APNs • Alert Orchestration)        │
├─────────────────────────────────────────────────────────────┤
│              Infrastructure & Data Layer                     │
│  (PostgreSQL • CloudKit • UserDefaults • FileSystem)         │
└─────────────────────────────────────────────────────────────┘
```

---

## Frontend Architecture (iOS)

### Core Managers

#### **AuthManager**
- **Purpose**: Centralized authentication + session management
- **Features**:
  - Phone OTP (E.164, HMAC-SHA256)
  - Apple Sign In (JWK verification)
  - Google OAuth (tokeninfo endpoint)
  - JWT issuance (HS256, 7-day expiry)
  - Keychain storage (secure token persistence)
  - Consent state tracking
- **Location**: `GeoWCS/AuthManager.swift`

#### **LocationTracker**
- **Purpose**: Real-time location capture + CloudKit publishing
- **Features**:
  - CLLocationManager with continuous + significant change modes
  - Altitude, accuracy, speed tracking
  - Consent + auth gating (only publish if authenticated + consented)
  - CloudKit record updates to friend list
  - Battery optimization with background modes
- **Location**: `GeoWCS/CoreLocation/LocationTracker.swift`

#### **GeofenceManager**
- **Purpose**: Geofence lifecycle + alert posting
- **Features**:
  - CLCircularRegion management
  - Region entry/exit detection
  - Arrival/Departure alert generation
  - Jest-backed API POST to `/v1/alerts`
  - Bearer token auth for GeoWCS backend
  - Timestamp + metadata capture
- **Location**: `GeoWCS/CoreLocation/GeofenceManager.swift`

#### **AudioRecorderManager**
- **Purpose**: Evidence capture via audio recordings
- **Features**:
  - AVAudioRecorder (MPEG-4 AAC, 44.1kHz stereo)
  - AVAudioPlayer with playback controls
  - FileManager persistence (`Documents/GeoWCSRecordings/`)
  - UserDefaults metadata (duration, fileSize, createdAt)
  - Share via UIActivityViewController
  - External file validation on load
- **Location**: `GeoWCS/Audio/AudioRecorderManager.swift`

#### **PushNotificationManager**
- **Purpose**: APNs device token registration + notification routing
- **Features**:
  - didRegisterForRemoteNotifications callback
  - Payload parsing (alertType, circleId, userId, geofenceId)
  - Foreground + background notification handling
  - AppDelegate integration
- **Location**: `GeoWCS/Notifications/PushNotificationManager.swift`

#### **EntitlementManager**
- **Purpose**: StoreKit 2 subscription entitlement verification
- **Features**:
  - Per-tier feature gating (Free vs Premium)
  - Live map access (premium-only)
  - Real-time sync updates
  - Transaction listener integration
- **Location**: `GeoWCS/Subscriptions/EntitlementManager.swift`

#### **CloudKitManager**
- **Purpose**: CloudKit record management
- **Features**:
  - Record type definitions (Friend, Location, Alert)
  - CRUD operations
  - Change tracking
- **Location**: `GeoWCS/CloudKit/CloudKitManager.swift`

### UI Architecture

#### **ContentView (Tab Navigation)**
- **Tabs**:
  1. **Map**: MapKit integration with friend overlay
  2. **Circle**: Friend group management  
  3. **Tracker**: Personal location settings
  4. **Safety**: Safety toolkit (check-in, geofences, audio)

#### **Safety Section**
- Designated contacts
- Check-in timer + SOS button
- Audio recorder sheet presentation
- Geofence management

#### **AudioRecorderView**
- Recording section (live waveform, start/stop button)
- Recordings list (play/pause, share, delete)
- Empty state guidance
- Error alerts

---

## Backend Architecture (NestJS)

### API Structure

```
POST /v1/auth/phone
POST /v1/auth/apple
POST /v1/auth/google
POST /v1/auth/token
POST /v1/circles
GET  /v1/circles/:id
POST /v1/circles/:id/members
POST /v1/alerts
GET  /v1/alerts
GET  /v1/health
```

### Core Services

#### **AuthService**
- Phone OTP validation (HMAC-SHA256)
- Apple Sign In verification (JWK endpoints)
- Google OAuth verification (tokeninfo API)
- JWT issuance + refresh
- Role-based access control (RBAC)

#### **AlertsService**
- Alert creation (arrival/departure)
- CircleId validation
- BullMQ job queue submission
- Database persistence

#### **CirclesService**
- Circle CRUD
- Membership management
- Friend list queries

#### **PresenceService**
- Real-time location tracking
- CloudKit sync coordination

### Queue Jobs (BullMQ)

#### **Geofence Processor**
- Triggered by iOS GeofenceManager alert POST
- Parses arrival/departure
- Calls APNs for group notification

#### **Notification Processor**
- APNs payload generation
- Device token lookup
- Multi-platform delivery (iOS)

#### **Presence Processor**
- Near-real-time location updates
- CloudKit sync coordination

### Data Models

```sql
Users:
  id (PK)
  phone
  email
  appleId
  googleId
  walletAddress
  subscriptionTier (Free/Premium)
  createdAt

Circles:
  id (PK)
  creatorId (FK: Users)
  name
  description
  maxMembers
  createdAt

CircleMembers:
  circleId (FK: Circles)
  userId (FK: Users)
  role (Creator/Member)
  joinedAt

Alerts:
  id (PK)
  circleId (FK: Circles)
  userId (FK: Users)
  geofenceId
  alertType (arrival/departure)
  timestamp
  latitude
  longitude
  metadata (JSON)

Geofences:
  id (PK)
  circleId (FK: Circles)
  name
  latitude
  longitude
  radiusMeters
  createdAt
```

---

## Data Storage

### Local (iOS)

| Storage | Purpose | Persistence |
|---------|---------|-------------|
| Keychain | JWT, auth tokens | Encrypted, survives app reinstall |
| UserDefaults | Audio metadata, consent flag | Plain text JSON |
| FileManager | .m4a audio files | `Documents/GeoWCSRecordings/` |
| CloudKit | Friend locations, circle data | Encrypted, cloud-synced |

### Remote (Backend)

| Database | Purpose |
|----------|---------|
| PostgreSQL | Users, circles, alerts, geofences |
| Redis | BullMQ job queue, session cache |
| APNs | Push notifications |
| CloudKit | Real-time sync (optional CloudKit subscription) |

---

## Authentication Flow

```
1. User enters phone → OTP sent (Twilio)
2. User verifies OTP
3. Backend generates JWT (HS256, 7-day exp)
4. JWT stored in Keychain
5. Subsequent requests attach JWT in Authorization: Bearer header
6. Backend validates JWT signature + exp
7. On expiry, user re-authenticates (OAuth option)
```

### Alternative OAuth Flows

**Apple Sign In**:
- Client → Apple → identity token
- Backend verifies JWK signature
- Create/update user record
- Return JWT

**Google OAuth**:
- Client → Google → access token
- Backend validates token with tokeninfo API
- Create/update user record
- Return JWT

---

## Geofence Alert Flow

```
1. iOS GeofenceManager detects region entry/exit
2. Calls CLCircularRegion callback (arrival/departure)
3. GeofenceManager POSTs alert to /v1/alerts with JWT
4. NestJS AlertsService creates Alert record
5. BullMQ GeofenceProcessor job triggered
6. Processor looks up circle members
7. For each member, enqueue Notification job
8. Notification job calls APNs with payload
9. iOS PushNotificationManager receives notification
10. Display to-user banner or lock screen alert
```

---

## Subscription Model

### StoreKit 2 Integration

**Tiers**:
- **Free**: SOS button, check-in timer, audio recording
- **Premium**: + Live map access, real-time friend tracking, unlimited circles

**Entitlement Verification**:
1. EntitlementManager listens to StoreKit transactions
2. On purchase, updates @Published entitlements
3. UI gates premium features via @EnvironmentObject check
4. Optional: Backend confirms entitlement on API calls

---

## Security Considerations

### App Layer
- ✅ Keychain storage for tokens (not UserDefaults)
- ✅ HTTPS only (URLSession default in iOS 9+)
- ✅ JWT exp validation + refresh
- ✅ Location gating (consent + auth)
- ✅ Audio file local-only (optional encryption)

### Backend Layer
- ✅ HMAC-SHA256 for OTP verification
- ✅ JWK verification for Sign In
- ✅ Rate limiting on auth endpoints
- ✅ CORS + CSRF protection
- ✅ Input validation + sanitization
- ✅ Environment-based secrets (.env)

### Network
- ✅ HTTPS/TLS 1.2+
- ✅ Certificate pinning (optional)
- ✅ API key rotation policy

---

## Deployment Architecture

### Development
- iOS: Simulator builds on local machine
- Backend: NestJS dev server (localhost:3000)
- Database: PostgreSQL local or Docker Compose

### Staging
- iOS: TestFlight via Xcode
- Backend: Azure Container Instances
- Database: Managed PostgreSQL

### Production
- iOS: App Store
- Backend: Azure App Service + Managed Identity
- Database: Azure Database for PostgreSQL
- Infrastructure: Bicep templates + Azure DevOps CI/CD

---

## Monitoring & Logging

- **iOS**: Console logs (XCon), crash reporting (Firebase)
- **Backend**: Winston logger, structured JSON logs
- **Database**: PostgreSQL query logs, audit trails
- **APNs**: Apple's notification delivery reports

---

## Future Enhancements

- [ ] Encrypted audio backups to CloudKit
- [ ] Speech-to-text transcription
- [ ] Geofence machine learning (anomaly detection)
- [ ] Integration with emergency services APIs
- [ ] Cross-platform (Android) support
- [ ] Web dashboard for admins
