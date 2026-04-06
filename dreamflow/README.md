<!-- markdownlint-disable -->

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

## AWS Middleware + Backend Deployment

Production AWS infrastructure is now defined in `infrastructure/aws` using Terraform.

Provisioned services:

- Amazon ECS Fargate service for the NestJS backend
- Application Load Balancer (public HTTP endpoint)
- Amazon RDS PostgreSQL for transactional data
- Amazon ElastiCache for Redis (middleware queue/cache backbone)
- Amazon SQS queue + DLQ for middleware async jobs
- Amazon SNS topic for backend notifications
- Amazon S3 bucket for middleware artifacts/exports
- CloudWatch Log Group for ECS application logs

Quick start:

1. Copy `infrastructure/aws/terraform.tfvars.example` to `infrastructure/aws/terraform.tfvars`
2. Set `api_container_image` and secure credentials (`db_password`, optional SMTP values)
3. Run from `infrastructure/aws`:

```bash
terraform init
terraform plan
terraform apply
```

After apply, use Terraform outputs to set app runtime:

- `backend_base_url`
- `rds_endpoint`
- `redis_primary_endpoint`
- `middleware_queue_url`
- `notifications_topic_arn`
- `middleware_artifacts_bucket`
- `db_password_secret_arn`
- `smtp_password_secret_arn`

When `AWS_SQS_MIDDLEWARE_QUEUE_URL`, `AWS_SNS_NOTIFICATIONS_TOPIC_ARN`, and `AWS_S3_MIDDLEWARE_BUCKET`
are configured, the API now publishes:

- presence ingestion events to SQS
- alert events to SQS and SNS
- JSON artifacts for presence and alerts to S3

Database and SMTP passwords are now injected via ECS `secrets` from AWS Secrets Manager
instead of plain task-definition environment variables.

Backend DB config supports either:

- `DATABASE_URL`
- or split vars `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_NAME`, `DATABASE_USER`, `DATABASE_PASSWORD`

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
- API docs runtime exposure:
	- OpenAPI/Swagger runtime endpoints are intentionally disabled in the API service.
	- See `docs/api-docs-reintroduction-plan.md` for a safe path to reintroduce API docs without adding runtime exposure in production.

## Generative AI Integrations

The API now supports a multi-provider GenAI gateway for text generation with provider fallback.

Endpoints:

- `GET /v1/genai/providers` returns configured providers and default models
- `POST /v1/genai/generate` generates text using `provider=auto|openai|anthropic|gemini|huggingface`

Local GenAI smoke validation command:

```bash
npm run test:e2e:genai
```

Supported provider environment keys:

- `OPENAI_API_KEY`, `OPENAI_TEXT_MODEL`
- `ANTHROPIC_API_KEY`, `ANTHROPIC_TEXT_MODEL`
- `GOOGLE_AI_API_KEY`, `GOOGLE_AI_MODEL`
- `HUGGINGFACE_API_KEY`, `HUGGINGFACE_MODEL`
- `GENAI_TIMEOUT_MS`

OpenAI multimodal support is also available via:

- `POST /media-support/image/analyze`
- `POST /media-support/video/analyze`

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

## Dependency Audit Status

The current npm audit baseline for the monorepo is clean (`0` known vulnerabilities).


- Key remediations applied:
	- `@nestjs/config` removed from API and worker workspaces (unused dependency).
	- `@nestjs/swagger` removed from API runtime and decorators (non-essential for production auth/circle/presence/alerts flows).
	- `npm audit fix` applied after dependency cleanup to reconcile remaining transitive vulnerabilities.
- Functional status after remediation:
	- `npm run test -w @dreamflow/api` passes
	- `npm run build -w @dreamflow/worker` passes
	- auth OTP send/verify integration tests remain green

## API Docs Reintroduction

If API reference docs are needed again, follow the staged hardening plan in:

- `docs/api-docs-reintroduction-plan.md`

Contract-first docs artifact generation is available now:

```bash
npm run docs:openapi
```

This emits a static OpenAPI file at `docs/openapi.generated.json`.
The generated contract now includes structured request and response schemas for each covered path.
It also includes concrete example payloads on request and success-response media types.

Current generated endpoint coverage includes:

- `/v1/circles` (create)
- `/v1/presence/location` (ingest ping)
- `/v1/auth/phone/send-otp`
- `/v1/auth/phone/verify-otp`
- `/v1/alerts` (create)
- `/v1/alerts/sos`

CI-ready validation command:

```bash
npm run ci:contracts
```

GitHub Actions workflow:

- `../.github/workflows/dreamflow-contracts.yml`
- On pull requests, the workflow also publishes a sticky contract summary comment with path/schema counts.
