# DreamFlow Monorepo Starter

DreamFlow is a modular, privacy-led mobile platform inspired by location safety architecture patterns (identity, circles, presence, alerts, history, device signals), adapted into its own product shape.

## Goals

- Export-ready for VS Code and Xcode workflows.
- Mobile-first architecture with clear feature boundaries.
- Consent-aware event ingestion and alerting.
- Separation of transactional data and telemetry workloads.

## Workspace Layout

- `apps/mobile`: React Native TypeScript app shell (Xcode/Android-ready folder structure).
- `apps/api`: NestJS middleware + BFF gateway.
- `apps/worker`: async jobs for geofence/alerts/presence pipelines.
- `packages/*`: shared types, schemas, API client, UI tokens/config.
- `infrastructure/docker`: local dev dependencies (Postgres/Redis/TimescaleDB).
- `docs`: architecture and event flow notes.

## Product Domains

- Identity
- Circles/Teams
- Presence & Location
- Flow Engine
- Alerts/SOS
- Insights

## Quick Start

1. Install Node 20+ and pnpm.
2. From this folder: `pnpm install`
3. Start API: `pnpm dev:api`
4. Start worker: `pnpm dev:worker`
5. Open mobile app project in VS Code and evolve native iOS under `apps/mobile/ios` in Xcode.

## Data Layer (Recommended)

- PostgreSQL: users, circles, memberships, geofences, alerts, subscriptions, consents.
- Redis: presence cache, websocket fan-out, queues.
- TimescaleDB/ClickHouse: location/motion telemetry and analytics.
- S3-compatible storage: exports, attachments, media.

## Privacy & Safety Defaults

- Explicit consent records per scope.
- Least-privilege access for circle visibility.
- Audit logs for sensitive reads/actions.
- Rate-limited event ingestion and idempotency keys.

## API Security Runtime

The Nest API now includes middleware and guards for baseline operational security.

- Request tracing: each request gets an `X-Request-Id` (generated if missing) and structured latency logs.
- Rate limiting: global throttling is enabled in the API module.
- Input hardening: validation pipes enforce whitelisting and reject unknown payload fields.
- Optional auth gate:
	- Set `API_AUTH_REQUIRED=true` to enforce auth for `/v1/*` endpoints (except health).
	- Provide either `API_AUTH_KEY` (for `x-api-key`) or `API_AUTH_TOKEN` (for `Authorization: Bearer <token>`).
	- If auth is required but no credentials are configured, API returns `503`.
- Role-based authorization:
	- Set `x-user-role` header to one or more comma-separated roles (`viewer`, `operator`, `admin`).
	- Route role requirements are enforced only when `API_AUTH_REQUIRED=true`.

### Local Example

```bash
API_AUTH_REQUIRED=true \
API_AUTH_KEY=dev-secret \
npm run dev:api
```

Then call a protected endpoint:

```bash
curl -H "x-api-key: dev-secret" \
	-H "x-user-role: viewer" \
	http://localhost:3000/v1/circles/user/user-a
```
