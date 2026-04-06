# GeoWCS Auth + API Setup

This document lists required dependencies, platform capabilities, and API keys for Google, Apple, Phone OTP, and OpenAI-backed features.

## 1. iOS Capabilities

Enable these in the app target:

- Sign In with Apple
- Push Notifications
- Background Modes:
  - location
  - remote-notification

Do not enable unrelated background modes (for example bluetooth/audio) unless the app behavior requires them.

## 2. Info.plist Keys

Configure these keys in the app target Info.plist:

- GeoWCSAPIBase
  - Example local: `http://localhost:3000`
  - Example cloud: `https://api.geowcs.dev`
- GoogleClientID
  - Accepts either full value (recommended):
    - 1234567890-abcdefg.apps.googleusercontent.com
  - Or raw prefix (legacy):
    - 1234567890-abcdefg
- GoogleReversedClientID (recommended)
  - Example:
    - com.googleusercontent.apps.1234567890-abcdefg
- GoogleRedirectScheme (optional fallback)
  - Same value as reversed client ID

## 3. URL Scheme Registration (Google OAuth callback)

Register URL scheme in the app target:

- CFBundleURLSchemes entry must include GoogleReversedClientID value
  - Example: com.googleusercontent.apps.1234567890-abcdefg

Without this, Google OAuth cannot return to the app after browser sign-in.

## 4. Backend Endpoints Required

GeoWCS auth UI expects these endpoints:

- POST /v1/auth/phone/send-otp
- POST /v1/auth/phone/verify-otp
- POST /v1/auth/google
- POST /v1/auth/apple

Local startup (from repo):

```bash
cd dreamflow/apps/api
npm install
npm run start:dev
```

## 5. Apple Sign-In Server Validation

Backend should verify Apple identity token against Apple's JWKS.

Apple references:

- <https://developer.apple.com/sign-in-with-apple/>
- <https://appleid.apple.com/auth/keys>

## 6. Google OAuth Requirements

Google Cloud Console setup:

- Create iOS OAuth client
- Add bundle ID: com.wcs.GeoWCS
- Record both:
  - Client ID
  - Reversed client ID (URL scheme)

The app uses PKCE with ASWebAuthenticationSession.

## 7. OpenAI API (RokMaxCreative)

OpenAI image generation path uses environment variable:

- OPENAI_API_KEY

Endpoint used in-app:

- `https://api.openai.com/v1/images/generations`

If OPENAI_API_KEY is missing, the app falls back to local image generation.

## 8. Quick Verification Checklist

- Google button opens browser and returns to app after consent
- Apple button shows native Sign in with Apple sheet
- Phone OTP advances from phone entry to code verification
- Auth errors show actionable backend/config hints instead of generic failures
