# GeoWCS App Store Submission Packet

Date: 2026-04-04
App: GeoWCS
Bundle ID: com.wcs.GeoWCS

## Rejection Evaluation (2026-04-04)

Most probable rejection reason from current shipped metadata and review flow constraints:

- App binary declared unsupported background modes:
	- `bluetooth-central`
	- `bluetooth-peripheral`
	- `audio`
- GeoWCS core functionality uses location + remote notifications for safety workflows, not Bluetooth background operation.
- This mismatch is a common App Review failure under performance/background capability rules.

Corrective actions applied:

- Removed Bluetooth/audio background modes from app metadata.
- Kept only required modes:
	- `location`
	- `remote-notification`
- Updated preflight policy to fail if unsupported background modes reappear.

Resubmission evidence required:

- New archive + IPA generated after metadata fix.
- Transporter verify/upload result captured.
- App Review notes retained with explicit test path.

## Upload Status

- Upload: SUCCEEDED
- Delivery UUID: 99348c83-4ed3-4ece-ab75-438042f9891f
- Uploaded At: 2026-04-04 10:08 (local)
- IPA: build/GeoWCS.ipa

## Packet Validation Command

Run before each submission:

./scripts/validate_app_store_packet.sh APP_STORE_SUBMISSION_PACKET.md

Full preflight (packet + IPA):

./scripts/app_store_preflight.sh APP_STORE_SUBMISSION_PACKET.md build/GeoWCS.ipa

## Final Recommended Listing Copy

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

## Field Limit Verification (Checked)

- Subtitle length: 22 / 30
- Promotional text length: 126 / 170
- Keywords length: 88 / 100
- Result: All constrained fields are within App Store limits

## Review Notes (Paste into App Review Information)

GeoWCS helps trusted contacts share live location, manage circles, and receive safety alerts.

Core flows to test:
1. Sign in with phone verification.
2. Create or join a circle.
3. Open live map and verify member location updates.
4. Configure geofence or safety alerts.

Demo account / access:
- No preconfigured account is required.
- Reviewer can create a new account using phone verification during review.
- If additional verification support is needed during review, contact: deployment@geowcs.dev

Hardware and permissions required:
- Location: Always or While Using the App
- Notifications: Allowed
- Cellular/Wi-Fi data access

If location or notifications are denied, some features (live tracking, geofence alerts, and safety notifications) are limited by design.

Content and compliance notes:
- No hidden or locked features are required for review.
- The app does not require external hardware.
- Any emergency or safety messaging is informational and not a substitute for emergency services.

Reviewer quick path:
1. Install build from TestFlight.
2. Complete phone sign-in.
3. Create a circle and open the map.
4. Enable location and notifications when prompted.
5. Trigger a location update and verify circle visibility.

## One-Pass Submission Checklist

- [ ] Open App Store Connect -> My Apps -> GeoWCS -> App Store -> iOS App
- [ ] Select processed build (uploaded 2026-04-04)
- [ ] Confirm category, content rights, and age rating
- [ ] Confirm App Privacy labels match app behavior
- [ ] Paste listing copy fields from this file
- [ ] Paste review notes from this file
- [ ] Set contact email: deployment@geowcs.dev
- [ ] Choose release mode (manual recommended)
- [ ] Add for Review / Submit for Review
- [ ] Monitor status: Waiting For Review -> In Review -> Pending Developer Release/Ready for Sale

## Submission Form Answers (Draft)

Use this as a starting point while completing App Store Connect forms. Confirm against your final implementation and legal/privacy policy.

### Export Compliance (Draft)

- Uses encryption: Yes (standard iOS TLS/HTTPS)
- Exempt from providing CCATS: Typically Yes for standard encryption only
- If prompted, select the option for standard encryption used for authentication and secure transport

### Content Rights (Draft)

- You own or have licensed all content included in the app and listing assets
- Confirm all icons, screenshots, and marketing text are original or properly licensed

### Age Rating (Draft)

- Set answers according to actual content
- If no explicit mature content is present, most categories are likely "None" or equivalent
- Safety/emergency context alone does not require a high age rating

### App Privacy Labels (Draft Starting Point)

Potential data categories used by app features:

- Contact Info:
	- Phone Number (account setup/verification)
- Identifiers:
	- User ID / account identifiers
- Location:
	- Precise location (live map, geofence alerts)
- User Content:
	- Audio recordings (stored on device by default)
- Diagnostics:
	- Crash/performance data (if enabled by your telemetry stack)

For each category in App Store Connect, confirm:

- Whether data is collected by the app or only remains on device
- Whether data is linked to the user
- Whether data is used for tracking across apps/sites (usually No unless ad-tracking SDKs are present)

### ATT (App Tracking Transparency) (Draft)

- If no cross-app tracking/ads SDKs are used, ATT prompt is typically not required
- If any tracking SDK exists, ATT prompt and privacy labels must be updated accordingly

### Reviewer Contact (Final)

- Email: deployment@geowcs.dev
- Phone: +1-000-000-0000
