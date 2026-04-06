# GeoWCS Fused Testing Handbook

## Purpose

This handbook defines one concrete testing system for GeoWCS by combining three complementary ideas into a single operating model for modern iOS Swift apps:

- Outside-in TDD and Red-Green-Refactor discipline.
- Contract-first thinking for backend and service boundaries.
- Swift-native XCTest and XCUITest techniques for unit, integration, async, and UI verification.

The intended outcome is fast feedback, stable releases, and test code that stays maintainable as the app expands across SwiftUI, Core Location, CloudKit, authentication, subscriptions, audio capture, and backend-driven workflows.

## Fusion Principles

The core loop is simple and non-negotiable:

1. Write a failing test for observable behavior.
2. Make it pass with the minimum production change.
3. Refactor test and production code while keeping the suite green.
4. Repeat in small increments.

This model exists to prevent speculative coding, surface design seams early, and turn the test suite into living documentation of how GeoWCS is expected to behave.

Shared operating rules:

- Test behavior, not private implementation details.
- Keep one main assertion idea per test.
- Build a fresh system under test for each test.
- Avoid shared mutable global state.
- Add one regression test for every production bug.
- Favor fast tests over broad but brittle end-to-end coverage.

## Target Architecture For Testability

The strongest testing system appears when the app is designed for testability before feature pressure hardens the codebase.

Recommended architecture:

- Domain layer: pure business rules, validation, mapping, transformations, and state machines.
- Presentation layer: thin SwiftUI views or view controllers with logic moved into view models, presenters, coordinators, or use cases.
- Data layer: adapters behind protocols for networking, persistence, authentication, analytics, media, and device services.
- API boundary: explicit endpoint, method, payload, auth, and error contracts.

For GeoWCS, this means most business logic should live outside SwiftUI view bodies and platform frameworks wherever practical. The most valuable code to unit test deeply is the code at the center of the system, not the code glued directly to UIKit, SwiftUI, CloudKit, APNs, or Core Location.

## The GeoWCS Test Pyramid

Target suite mix:

- 70-80% unit tests.
- 15-20% integration and contract tests.
- 5-10% UI smoke tests.

Layer guidance:

| Layer | Main goal | Swift toolset | Guidance |
|---|---|---|---|
| UI smoke tests | Prove major journeys work end to end | XCUITest | Keep the suite small, stable, and focused on critical paths. |
| Feature acceptance tests | Verify user-visible behavior at a high level | XCTest or XCUITest as justified | Start from user stories and drive implementation outside-in. |
| API contract tests | Lock client and backend into the same agreement | XCTest with fixtures and decoders | Verify URL shape, methods, payloads, auth, and failure formats. |
| Integration tests | Check real adapters against subsystem seams | XCTest | Cover persistence, decoding, caching, notification, and service adapters. |
| Unit tests | Protect business logic with speed and precision | XCTest | These should make up the bulk of the suite. |
| Async tests | Verify timing and callback correctness | XCTestExpectation and related APIs | Cover completions, retries, notifications, cancellation, and state changes. |

Practical interpretation for this repository:

- `GeoWCSTests/Unit/` should carry the majority of coverage.
- `GeoWCSTests/Integration/` should verify multi-component flows and adapter behavior.
- Contract tests should live either under `GeoWCSTests/Integration/` or a dedicated `GeoWCSTests/Contracts/` area if volume grows.
- `GeoWCSUITests/` should stay intentionally small and focused on release-critical user journeys.

## Current Repo Alignment

The existing GeoWCS structure already supports this model:

- `GeoWCSTests/Unit/`
- `GeoWCSTests/Integration/`
- `GeoWCSTests/RokMaxCreative/`
- `GeoWCSTests/DementiaMedia/`
- `GeoWCSUITests/`
- `build/test-results/`

Recommended incremental support structure:

- `GeoWCSTests/Support/Fixtures/`
- `GeoWCSTests/Support/Builders/`
- `GeoWCSTests/Support/Fakes/`
- `GeoWCSTests/Support/Spies/`
- `GeoWCSTests/Support/Mocks/`

If contract coverage becomes significant, add:

- `GeoWCSTests/Contracts/`

That folder should contain JSON fixtures, request builders, and response decoding assertions that lock the mobile client to expected backend behavior.

## Operating Rules

### Red-Green-Refactor

Every feature starts with a failing test, moves to the smallest change required to pass, and ends with cleanup. If code was written before the first test, the TDD signal has already been weakened.

### Test Behavior, Not Implementation

Prefer assertions about:

- outputs
- visible state
- emitted events
- protocol interactions that matter to behavior
- user-visible consequences

Avoid testing:

- private helper details
- storage format that is not part of behavior
- framework internals
- constants and incidental implementation choices

### One Idea Per Test

Each test should state one meaningful behavioral claim. Strong names should encode setup, action, and expected result.

Examples:

- `testLogin_withInvalidPassword_showsValidationError`
- `testFetchProfile_whenServerReturns401_emitsUnauthorizedState`
- `testSaveDraft_persistsEncodedPayload`
- `testArmCheckIn_whenDurationExpires_emitsMissedCheckInAlert`

### Isolate Tests Completely

Rules:

- Create a fresh system under test for every test.
- Avoid shared mutable global state.
- Reset singletons if legacy code forces them to exist.
- Ensure test data does not leak across test cases.
- Randomize order in CI to expose inter-test coupling.

## Concrete System Design For Swift In GeoWCS

### 1. Domain Tests First

Domain tests should cover logic fully under team control, including:

- validation rules
- permission logic
- transformations and mapping
- sorting and filtering
- geofence decision rules
- check-in timer behavior
- subscription entitlement rules
- workflow state machines

These tests should not require real UI rendering, CloudKit, network traffic, disk access, or simulator-driven behavior unless the behavior truly belongs at that boundary.

Likely candidate areas in this repo:

- `Auth/`
- `Subscription/`
- `CoreLocation/`
- `CloudKit/Domain-like mapping logic`
- `MapKit/LiveMapViewModel.swift`
- `DementiaMedia/Domain/`

### 2. Protocol-Driven Dependency Seams

All external collaborators should sit behind protocols before the codebase hardens further.

Recommended seams for GeoWCS:

- `APIClient`
- `ImageLoader`
- `AuthStore`
- `SessionStore`
- `AnalyticsTracker`
- `Clock`
- `UUIDGenerator`
- `ReachabilityChecking`
- `LocationManaging`
- `CloudKitManaging`
- `NotificationScheduling`
- `AudioRecording`

Preferred doubles:

- Stub: deterministic return values.
- Spy: records important calls for assertions.
- Fake: lightweight in-memory implementation.
- Mock: strict interaction verification when behavior is best described through collaboration.

Avoid giant all-purpose mocks. Small, specific doubles are easier to trust and maintain.

### 3. Async Test Discipline

Every async boundary should have tests for:

- success completion
- failure completion
- timeout or retry behavior where applicable
- loading-state transitions
- cancellation behavior where business risk is high
- notification-driven state changes

Implementation rules:

- Prefer `XCTestExpectation` or explicit async waiting APIs.
- Avoid raw `sleep` unless there is no reliable synchronization hook.
- Make time, retries, and debounce logic injectable where possible.

High-risk GeoWCS async surfaces include:

- auth flows
- location tracking updates
- CloudKit synchronization
- push notification registration
- audio recording state changes
- StoreKit entitlement refresh

### 4. REST And Service Contract Tests

Backend and service boundaries should be treated as formal contracts, not informal assumptions.

For each important endpoint or service interaction, verify:

- path generation and URL composition
- HTTP method correctness
- required headers, tokens, and auth behavior
- request encoding
- response decoding
- error payload mapping to domain-friendly errors
- handling of missing, null, or extra fields
- pagination, media URLs, and cache directives where applicable

Even when GeoWCS uses platform-native services like CloudKit, the same principle applies: the client should have explicit expectations about schema, record translation, and error behavior.

### 5. UI Automation Only For Critical Paths

Use UI tests only where end-to-end confidence is worth the runtime and maintenance cost.

Recommended GeoWCS UI smoke scope:

- app launch
- session restoration or sign-in
- onboarding completion
- trusted circle creation or join flow
- primary map/tracking journey
- one revenue-critical subscription path
- one safety-critical alert path such as SOS or missed check-in

Do not push every view-state assertion into XCUITest. Lower layers should carry most of the behavioral coverage.

## Suggested Development Workflow

### Feature Workflow

1. Write one user-story scenario using outside-in thinking.
2. Add one high-level feature or UI test only if the feature is risky enough to justify it.
3. Break the problem into domain logic, presentation logic, data access, and contract seams.
4. Write focused unit tests for domain and presentation layers first.
5. Add integration or contract tests around networking, persistence, serialization, or service boundaries.
6. Implement the minimum production code to go green.
7. Refactor both test and production code while the suite stays green.
8. Add a targeted regression test when a bug is found.

### Bug-Fix Workflow

1. Reproduce the bug with the smallest failing test possible.
2. Fix it at the correct layer: domain, mapping, presentation, persistence, or UI.
3. Add only the minimum production change needed.
4. Refactor if the bug exposed a structural smell.

## XCTest-Specific Standards

Adopt these mechanics consistently:

- Use `XCTestCase` as the base abstraction.
- Use `setUp` and `tearDown` rigorously.
- Use `sut` naming when it improves readability.
- Use the right `XCTAssert` variant intentionally.
- Use expectations for asynchronous behavior.
- Review code coverage to find unexecuted branches and blind spots.
- Randomize order in CI to catch state leakage.
- Do not change production code solely to satisfy low-value tests.

## API And Mobile Boundary Standards

Use service-boundary thinking across mobile features:

- design stable endpoints and interaction semantics
- think in CRUD and state-transition contracts, not only screens
- make the API client or service adapter an explicit component
- treat async remote failures as normal cases to model and test
- test auth, image/media loading, and remote fetch behavior directly

This applies equally to external HTTP APIs, CloudKit records, APNs registration, StoreKit receipts, and any other boundary where GeoWCS depends on data or behavior outside the core domain.

## CI Quality Gates

The suite only creates leverage if it runs automatically and produces a trustworthy signal.

Required gates:

- Run all unit, integration, and contract tests on every pull request.
- Run UI smoke tests on merges to `main` and on release branches.
- Fail the pipeline on deterministic failures, uncaught crashes, and repeated flaky retries.
- Track code coverage trends, especially for domain and networking-heavy modules.
- Keep test duration visible so the suite does not silently become too slow.
- Randomize order for at least one CI lane.

Recommended local and CI commands in this repo:

- `bash scripts/run-tests.sh unit`
- `bash scripts/run-tests.sh integration`
- `bash scripts/run-tests.sh ui`
- `bash scripts/run-tests.sh dearts`
- `bash scripts/run-tests.sh all`

Available focused Xcode tasks in this workspace include:

- `DeArtsWCS Unit+Integration`
- `DeArtsWCS UI Flows`
- `DeArtsWCS Full Test Sweep`

## Anti-Patterns To Avoid

Avoid these failure modes:

- writing production code before the test that should drive it
- overusing UI tests for logic that belongs in unit tests
- using `sleep` where expectations or explicit waits can be used
- testing framework internals instead of team-owned behavior
- coupling tests to fragile strings, labels, or incidental implementation details
- sharing mutable state between tests
- building giant all-knowing mocks instead of small purposeful doubles
- trusting backend or service behavior without contract verification

## Implementation Checklist

- Keep separate test targets for app tests and UI tests.
- Introduce protocol seams for external dependencies before modules harden.
- Build and maintain a fixtures library for payloads and error responses.
- Keep domain logic out of SwiftUI views and view controllers where possible.
- Add one regression test for every production bug.
- Replace fragile sleeps with expectations and explicit waits.
- Enable and review code coverage regularly.
- Run the full suite continuously in CI.

## GeoWCS Rollout Plan

### First 30 Days

1. Enforce naming, isolation, and Red-Green-Refactor conventions in all new tests.
2. Stop adding logic directly to SwiftUI views where extraction to view models or use cases is practical.
3. Identify missing seams in high-change modules such as auth, tracking, subscription, and media.

### Days 31-60

1. Build `Fixtures`, `Builders`, `Fakes`, `Spies`, and `Mocks` support folders.
2. Add contract coverage for the most important backend or CloudKit-facing behaviors.
3. Add deterministic async coverage for retries, loading states, and failure mapping.

### Days 61-90

1. Trim flaky UI tests and keep only top-risk smoke flows.
2. Add CI reporting for duration, coverage trend, and failure concentration.
3. Use production bugs to drive regression coverage in weak areas of the pyramid.

Success metrics:

- stable PR signal with low rerun rate
- faster median feedback time
- stronger domain and contract coverage
- fewer regressions in critical map, auth, tracking, and alert flows

## Closing Synthesis

The strongest testing system for GeoWCS is not purely Swift testing and not purely general TDD theory. It is a fusion:

- outside-in TDD supplies the strategic discipline
- contract-first thinking supplies boundary rigor
- XCTest and XCUITest supply the native execution model

That combination creates a test system that is fast where it should be fast, deep where business risk is highest, and stable enough to support long-lived iOS releases with complex behavior.
