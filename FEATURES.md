# GeoWCS Features

## Core Safety Features

### 🗺️ Real-Time Location Sharing
**Status**: ✅ Production Ready

Share your location with trusted circles in real-time.

- **Free Tier**: View your own location history
- **Premium Tier**: Live map with friend overlays, real-time tracking
- **Privacy**: Location only shared when:
  - Actively signed in
  - Consent granted via in-app toggle
  - Opted into circle sharing
- **Technology**: MapKit, CoreLocation, CloudKit

---

### 🚨 Geofence Alerts
**Status**: ✅ Production Ready

Get notified when friends arrive or depart from important locations.

- **Circle Admin**: Set up geofences for shared locations
- **Automatic Alerts**: Triggered on arrival/departure (50m radius)
- **Push Notifications**: iOS push via APNs
- **Alert History**: 30-day alert archive
- **Technology**: CLCircularRegion, APNs, BullMQ

---

### 📱 Check-In System
**Status**: ✅ Production Ready

Check in at locations to let your circle know you're safe.

- **One-Tap Check-In**: Quick indicator of arrival
- **Automatic Check-In**: Optional based on location
- **Check-In Timer**: Set check-in reminders
- **Notification**: Circle members notified of check-ins
- **Technology**: CloudKit sync, push notifications

---

### 🎤 Audio Evidence Recording
**Status**: ✅ Production Ready (Phase 10)

Record audio evidence during safety incidents.

- **Local Storage**: Encrypted files on device
- **Easy Sharing**: Share via AirDrop, Mail, Messages
- **Metadata**: Duration, timestamp, file size tracking
- **No Cloud Required**: Recordings stay private by default
- **Playback**: Play, pause, delete recordings
- **Formats**: MPEG-4 AAC, 44.1kHz stereo, high quality
- **Technology**: AVAudioRecorder, AVAudioPlayer, FileManager

**Use Cases**:
- Record incidents during emergencies
- Capture witness statements
- Document threats or harassment
- Standalone evidence archive

---

### 🆘 SOS Button
**Status**: ✅ Production Ready

One-tap emergency alert to your entire circle.

- **One-Second Activation**: Long-press SOS button
- **Full Alerts**: Location, timestamp, device info sent
- **Escalation**: Repeat SOS triggers optional emergency contact
- **Confirmation**: Circle gets notification of SOS activation
- **Technology**: CoreLocation, APNs, Background modes

---

### 👥 Trusted Contacts
**Status**: ✅ Production Ready

Define your safety circle.

- **Quick Add**: Add contacts by phone or Apple ID
- **Roles**: Admin (manage circle) or Member
- **Permissions**: Granular access control (view location, see alerts, etc.)
- **Invite System**: Send invitations to friends
- **Family Plan**: Designate family members
- **Technology**: CloudKit, UserDefaults

---

### 🔔 Smart Notifications
**Status**: ✅ Production Ready

Intelligent push notifications based on context.

- **Arrival/Departure**: Geofence triggers
- **SOS Alerts**: Emergency activations
- **Circle Updates**: New members, new geofences
- **Do Not Disturb**: Respect system settings
- **Sound/Vibration**: Customizable per alert type
- **Technology**: APNs, UserNotifications

---

## Authentication & Security

### 🔐 Multi-Factor Authentication
**Status**: ✅ Production Ready

- **Phone OTP**: SMS-based 6-digit codes (E.164 format)
- **Apple Sign In**: Secure authentication via Apple
- **Google OAuth**: Authenticate with Google account
- **JWT Tokens**: 7-day bearer token expiry
- **Keychain Storage**: Secure token persistence
- **Technology**: Twilio SMS, JWK verification, HS256

---

### 🛡️ End-to-End Encryption
**Status**: 🔄 Planned

- Encrypt location data in transit
- Encrypt audio files at rest
- Encrypt CloudKit records
- Zero-knowledge architecture option

---

### 🔓 Privacy Controls
**Status**: ✅ Production Ready

Fine-grained privacy settings.

- **Location Sharing**: Toggle on/off per circle
- **Consent Banner**: In-app consent flow
- **Data Retention**: Auto-delete old location data
- **Opt-Out**: Remove from circles anytime
- **Technology**: UserDefaults, AuthManager state

---

## Subscription Tiers

### Free Tier
- ✅ SOS button
- ✅ Check-in system
- ✅ Audio recording & playback
- ✅ Trusted contact management
- ✅ Phone authentication
- ✅ Geofence setup (create only)
- ❌ Real-time map
- ❌ Live friend tracking
- ❌ Unlimited circles (max 1)

### Premium Tier ($4.99/month)
- ✅ All Free tier features
- ✅ Real-time map with friend overlays
- ✅ Live location tracking
- ✅ Unlimited circles
- ✅ Unlimited geofences
- ✅ Priority support
- ✅ Advanced analytics (future)
- ✅ Family sharing (2-4 people)

---

## Integrations

### 🍎 Apple Ecosystem
- **CloudKit**: Real-time data sync
- **MapKit**: Map rendering
- **StoreKit 2**: Subscription management
- **CoreLocation**: Geofencing + GPS
- **AVFoundation**: Audio recording
- **UserNotifications**: Local alerts
- **Keychain**: Secure storage

### 🌐 External APIs
- **Twilio**: SMS OTP delivery
- **Apple Sign In**: OAuth provider
- **Google OAuth**: OAuth provider
- **APNs**: Push notifications
- **OpenWeather** (future): Location-based weather

---

## Premium Features (Roadmap)

### 🎥 Video Recording
Record video evidence during incidents.

- **Limited Duration**: 30-second clips
- **Quick Share**: Export to Messages/Photos
- **Scheduled**: Queue multiple clips

### 📊 Analytics Dashboard
Insights into safety patterns.

- **Alert Trends**: Charts of alerts over time
- **Hotspots**: Map of frequent geofence triggers
- **Member Activity**: Who's checking in most
- **Export**: CSV/PDF reports for insurance

### 🤖 AI-Powered Alerts
Anomaly detection and smart filtering.

- **Unusual Location**: Alert if friend departs normal route
- **Unusual Time**: Alert if check-in outside normal hours
- **Clustering**: Group nearby alerts smartly

### 🚨 Emergency Service Integration
Direct connections to local authorities.

- **One-Tap Dispatch**: Send location directly to 911
- **Call Integration**: Initiate voice call to emergency
- **Location Sharing**: Persistent location share with dispatcher

### 🏢 Enterprise Features
Organization-wide safety management.

- **Admin Dashboard**: Bulk user/geofence management
- **Audit Logs**: Complete activity history
- **SSO**: Single sign-on for employees
- **DLP**: Data loss prevention policies
- **Advanced RBAC**: Role-based access control

---

## Performance Metrics

### Location Updates
- **Frequency**: Every 1-10 minutes (adaptive)
- **Battery Impact**: <2% increase vs baseline
- **Network**: ~50KB per update

### Push Notifications
- **Latency**: <2 seconds from geofence trigger to notification
- **Reliability**: 99.5% delivery rate (APNs SLA)
- **Payload**: ~200 bytes

### Audio Recording
- **Bitrate**: 128 kbps (AAC)
- **Filesize**: ~1MB per minute
- **Latency**: <100ms start time

### Map Rendering
- **Zoom**: 18 levels (local to global)
- **Overlay**: Real-time location dots for circle members
- **Tiles**: Vector-based (MapKit)

---

## Known Limitations

### Current Version
- iOS only (Android: Q3 2026 roadmap)
- Max 50 circles per user
- Max 100 geofences per circle
- 24-hour location data retention
- 180-day alert history

### Planned Fixes
- Increase circle/geofence limits (Q2 2026)
- Longer data retention (Q2 2026)
- Encrypted local storage (Q3 2026)
- Web dashboard (Q4 2026)

---

## Feature Requests

Have a suggestion? 

- Vote on [Feature Board](https://feedback.geowcs.dev)
- Email: features@geowcs.dev
- Slack Community: #feature-ideas

---

## Release History

### v1.0.0 (Apr 2, 2026) - Launch
- Core location sharing
- Geofence alerts
- Audio recording
- Phone OTP auth
- StoreKit 2 subscriptions
- iOS Simulator verified

### v0.9.0 (Mar 15, 2026) - Beta
- Testing with beta users
- Geofence live map
- Push notifications

### v0.5.0 (Mar 1, 2026) - Alpha
- Initial backend framework
- Auth endpoints
- CloudKit integration

