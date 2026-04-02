# DreamFlow Architecture

## High-Level Flow
Mobile App (React Native / iOS / Android)
-> API Gateway/BFF (NestJS)
-> Modules (Auth, Circles, Presence, Timeline, Alerts)
-> Queue/Event Processing (Worker)
-> PostgreSQL + Redis + TimescaleDB
-> Push channels (APNs/FCM) and analytics

## Domain Split
- Identity
- Circles/Teams
- Presence & Location
- Flow Engine
- Alerts/SOS
- Insights

## Event Pipeline
1. Mobile sends location + activity ping.
2. API validates auth + consent scope.
3. API writes event to queue.
4. Worker updates presence cache and durable timeline stores.
5. Geofence processor emits transition events.
6. Notification job delivers push and in-app alerts.

## Initial API Surface
- `POST /v1/circles`
- `GET /v1/circles/:id`
- `POST /v1/presence/location`
- `POST /v1/alerts/sos`
- `GET /v1/health`

## Schema Starter (Core)
- users, profiles, circles, circle_members, invites
- devices, device_tokens, places, geofences
- alerts, sos_incidents, subscriptions, consents, audit_logs

## Schema Starter (Telemetry)
- location_events, motion_events, geofence_events, presence_snapshots
