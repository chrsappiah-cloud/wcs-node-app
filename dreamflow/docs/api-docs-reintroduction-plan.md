# API Docs Reintroduction Plan (Safe-by-Default)

This plan restores API discoverability without reintroducing OpenAPI runtime attack surface in production.

## Current State

- API runtime does not expose `/v1/docs`.
- `@nestjs/swagger` is removed from API runtime dependencies.
- Security baseline and auth tests are currently green.
- Option A scaffold is implemented:
	- Command: `npm run docs:openapi`
	- CI command: `npm run ci:contracts`
	- Artifact: `docs/openapi.generated.json`
	- Generator: `scripts/generate-openapi-contracts.ts`
	- CI workflow: `../.github/workflows/dreamflow-contracts.yml`
	- Generated contracts now include both request and response schemas for covered endpoints.
	- Generated contracts include concrete request/response examples for covered endpoints.
	- PR runs publish a sticky contract summary comment with endpoint/schema counts.
	- Generated paths currently cover:
		- `/v1/circles`
		- `/v1/presence/location`
		- `/v1/auth/phone/send-otp`
		- `/v1/auth/phone/verify-otp`
		- `/v1/alerts`
		- `/v1/alerts/sos`

## Goals

- Provide accurate API reference for internal development and integration testing.
- Keep production API runtime free of docs tooling and docs routes.
- Preserve current `npm audit` clean state.

## Non-Goals

- No public internet docs endpoint from production API service.
- No requirement to restore decorator-heavy runtime docs metadata in controllers.

## Recommended Architecture

Use a docs generation workflow that is isolated from production runtime:

1. Contract source of truth:
- Define API request/response contracts in shared packages (prefer `packages/schemas`).
- Keep DTO validation and schema contracts aligned in CI.

2. Build-time docs generation:
- Generate OpenAPI JSON as a build artifact in CI or local tooling.
- Publish the static artifact (JSON + optional HTML) to internal hosting only.

3. Runtime isolation:
- Do not add OpenAPI routes to `apps/api` runtime.
- Keep docs generation dependencies outside API production install path.

## Implementation Options

### Option A: Contract-First (preferred)

- Use schema definitions in `packages/schemas` and generate OpenAPI from them.
- Pros:
- No runtime reflection/decorator dependency in API.
- Explicit contract ownership and versioning.
- Better compatibility with static analysis and client generation.
- Cons:
- Requires up-front contract maintenance discipline.

### Option B: Dedicated Docs Tooling Workspace

- Add a separate workspace (for example, `tools/api-docs`) that imports API metadata and emits static docs.
- Keep this workspace out of runtime deployment images.
- Pros:
- Familiar OpenAPI flow.
- Keeps runtime separation.
- Cons:
- Additional tooling workspace to maintain.

## Security Controls (Required)

- Do not enable docs endpoint in production API.
- If internal preview docs are hosted, require SSO or equivalent access control.
- Add CI checks to fail if API runtime reintroduces `@nestjs/swagger` or `/v1/docs` routes without approval.
- Keep generated docs free of secrets, internal hostnames, or sample tokens.

## CI Policy Checks

Add checks that enforce:

- `npm audit` remains clean in the monorepo.
- API tests continue to pass.
- Worker build continues to pass.
- Docs artifact generation succeeds (when enabled).

## Rollout Plan

### Phase 1: Foundation

- Choose Option A or Option B.
- Define ownership for contract updates.
- Add CI guardrails for runtime docs-route prevention.

### Phase 2: Generation

- Generate and store OpenAPI artifact in CI.
- Add internal artifact publishing.
- Validate generated specs against integration tests.

### Phase 3: Consumer Enablement

- Provide internal docs URL/artifact path.
- Add guidance for client generation and contract versioning.
- Track breaking changes via changelog and schema versioning.

## Exit Criteria

- API runtime remains docs-route free in production.
- Internal API docs are available and versioned.
- No regression in auth/security tests.
- `npm audit` remains at zero known vulnerabilities.
