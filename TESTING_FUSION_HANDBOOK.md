# GeoWCS Fused Testing Handbook (iOS Swift)

## Purpose

This handbook defines one practical testing system for GeoWCS by combining:

- Outside-in TDD discipline (Red-Green-Refactor)
- API contract-first thinking for service boundaries
- Swift-native XCTest and XCUITest implementation patterns

The goal is fast feedback, stable releases, and test code that stays maintainable as the app grows.

## Core Model

Every feature follows this loop:

1. Write a failing test for observable behavior.
2. Implement the minimum production change to pass.
3. Refactor production and test code while keeping green.
4. Repeat in small increments.

Rules:

- Test behavior, not private implementation details.
- Keep one core assertion idea per test.
- Build a fresh SUT per test.
- Avoid shared mutable global state.
- Add one regression test for every production bug.

## Target Architecture For Testability

Design seams first so tests can stay small and deterministic:

- Domain layer: pure rules, validation, state transitions, transformations.
- Presentation layer: thin views/view controllers; logic in view models/use cases.
- Data layer: protocol-backed adapters for network, persistence, auth, analytics, media.
- API boundary: explicit endpoint, method, payload, auth, and error contracts.

## Test Pyramid For GeoWCS

Target mix:

- 70-80% unit tests
- 15-20% integration + contract tests
- 5-10% UI smoke tests

Layer guidance:

- Unit tests: business logic, rules, state machines, mapping.
- Integration tests: real adapter interactions (network/persistence/cache/decoding).
- Contract tests: request/response compatibility between app client and backend.
- UI smoke tests: launch + highest-risk user journeys only.

## GeoWCS Test Layout

Current project-aligned structure:

- `GeoWCSTests/Unit/`
- `GeoWCSTests/Integration/`
- `GeoWCSTests/RokMaxCreative/` (DeArtWCS-focused unit/integration)
- `GeoWCSUITests/` (critical UI journeys)
- `build/test-results/` (xcresult artifacts)

Recommended support grouping (incremental migration):

- `GeoWCSTests/Support/Fixtures/`
- `GeoWCSTests/Support/Builders/`
- `GeoWCSTests/Support/Fakes/`
- `GeoWCSTests/Support/Spies/`
- `GeoWCSTests/Support/Mocks/`

## Protocol Seams Required

External collaborators must be abstracted before feature expansion hardens code:

- `APIClient`
- `SessionStore`
- `AuthStore`
- `ImageLoader`
- `AnalyticsTracker`
- `Clock`
- `UUIDGenerator`
- `ReachabilityChecking`

Preferred doubles:

- Stub: deterministic return values
- Spy: record interaction for assertions
- Fake: lightweight in-memory implementation
- Mock: strict interaction contract when needed

## Async Testing Rules (XCTest)

For each async boundary, cover:

- Success path
- Failure path
- Timeout/retry path (if applicable)
- Loading state transitions
- Cancellation/race behavior for high-risk workflows

Implementation expectations:

- Prefer `XCTestExpectation` and explicit waits.
- Avoid raw `sleep` unless no reliable synchronization hook exists.

## API Contract Coverage

For each important endpoint, verify:

- URL/path composition
- HTTP method
- Required headers/tokens
- Request encoding
- Response decoding
- Error mapping
- Null/missing/extra fields behavior
- Pagination/caching semantics (where used)

## UI Automation Scope

Keep UI tests intentionally small and stable. Focus on:

- App launch
- Session restore/sign-in
- Onboarding completion
- Core CRUD journey
- Revenue/compliance critical paths

Do not move domain logic checks to UI tests when lower layers can cover them.

## Workflow

### Feature Workflow

1. Define one user-story scenario.
2. Add a high-level acceptance/UI test only if risk justifies it.
3. Break work into domain, presentation, data, and contract seams.
4. Drive domain/presentation with unit tests first.
5. Add integration/contract tests at boundaries.
6. Implement minimum code to go green.
7. Refactor while preserving green.

### Bug Workflow

1. Reproduce with the smallest failing test.
2. Fix at the correct layer.
3. Apply minimum production change.
4. Refactor when structural smell is exposed.

## CI Quality Gates

Required gates:

- Run unit + integration + contract tests on every PR.
- Run UI smoke tests on `main` merges and release branches.
- Fail on crashes, deterministic failures, and repeated flaky retries.
- Track coverage trend for domain/networking modules.
- Track suite duration to prevent regression in feedback time.

## GeoWCS Commands

Use the canonical script:

- `bash scripts/run-tests.sh unit`
- `bash scripts/run-tests.sh integration`
- `bash scripts/run-tests.sh ui`
- `bash scripts/run-tests.sh dearts`
- `bash scripts/run-tests.sh all`

## Anti-Patterns

- Writing production code before driving behavior with tests.
- Overusing UI tests for logic-level behavior.
- Coupling tests to unstable implementation details.
- Shared mutable state across tests.
- Oversized all-purpose mocks.
- Treating backend behavior as implicit without contract checks.

## Rollout Plan (90 Days)

1. Weeks 1-2: Enforce naming/isolation conventions in all new tests.
2. Weeks 3-4: Add missing protocol seams in high-churn modules.
3. Weeks 5-8: Build fixtures/builders/fakes support library.
4. Weeks 9-10: Expand API contract tests for critical endpoints.
5. Weeks 11-12: Trim flaky UI tests and keep top-risk smoke flows only.

Success metrics:

- Stable PR signal (low rerun rate)
- Faster median test runtime
- Higher domain/contract coverage
- Reduced production regressions in critical flows
