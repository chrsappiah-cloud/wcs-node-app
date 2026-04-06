# GeoWCS Testing System

## Overview

GeoWCS uses XCTest and XCUITest as the primary testing stack for iOS code. The repo follows a layered model:

- fast unit tests for business logic
- integration tests for subsystem boundaries and adapters
- a small UI smoke suite for critical user journeys

For the full outside-in TDD and contract-first operating model, see `TESTING_FUSION_HANDBOOK.md`.

## Why XCTest And XCUITest

For a native Swift iOS app, XCTest is the default choice because it is built into Xcode, integrates directly with simulator execution, produces first-class result bundles, and avoids the extra flakiness and infrastructure overhead of browser-style or cross-platform black-box tools.

Use XCUITest only where end-to-end confidence is worth the runtime and maintenance cost. Most behavioral coverage should remain in unit and integration layers.

## Test Pyramid

Recommended target mix:

- 70-80% unit tests
- 15-20% integration and contract-boundary tests
- 5-10% UI smoke tests

This matches the current repository direction:

- `GeoWCSTests/Unit/` for pure logic
- `GeoWCSTests/Integration/` for subsystem flows
- `GeoWCSTests/DementiaMedia/` for feature-specific unit, integration, quality, and performance suites
- `GeoWCSTests/RokMaxCreative/` for DeArtsWCS-focused coverage
- `GeoWCSUITests/` for critical UI paths

## Current Test Areas

### Core Unit Tests

Representative coverage includes:

- `GeoWCSTests/Unit/CheckInTimerTests.swift`
- `GeoWCSTests/Unit/SafetyEngineTests.swift`
- `GeoWCSTests/DementiaMedia/Unit/*.swift`
- `GeoWCSTests/RokMaxCreative/*Tests.swift` where tests exercise isolated app logic

Focus these tests on rules, state transitions, validation, transformations, and framework-independent behavior.

### Integration Tests

Representative coverage includes:

- `GeoWCSTests/Integration/TrackerIntegrationTests.swift`
- `GeoWCSTests/DementiaMedia/Integration/*.swift`
- `GeoWCSTests/RokMaxCreative/DeArtsWCSSeedModeIntegrationTests.swift`
- `GeoWCSTests/RokMaxCreative/DeArtsWCSIntegrationTests.swift`

These tests should verify component boundaries such as location tracking, persistence, media adapters, and service translation behavior.

### UI Smoke Tests

Representative UI coverage includes:

- `GeoWCSUITests/GeoWCSCriticalFlowsUITests.swift`
- `GeoWCSUITests/DeArtsWCSCriticalFlowsUITests.swift`
- `GeoWCSUITests/DementiaMedia/*.swift`

Keep UI scope intentionally narrow. Use it for launch, onboarding, sign-in/session restoration, core task completion, and other release-critical flows.

## Test Runner

The canonical local entry point is:

```bash
bash scripts/run-tests.sh [unit|integration|ui|dearts|coverage|performance|all]
```

Supported modes:

- `unit`: runs the core unit suite selected in the script
- `integration`: runs the core integration suite selected in the script
- `ui`: runs the UI suite after preparing a clean simulator
- `dearts`: runs the focused DeArtsWCS sweep
- `coverage`: runs the full suite with coverage enabled
- `performance`: runs the performance test pass
- `all`: runs unit, integration, and UI suites

The script writes logs and artifacts to:

- `build/test-results/`
- `build/coverage/`
- `build/DerivedData/`

## Local Commands

Run the main suites with:

```bash
bash scripts/run-tests.sh unit
bash scripts/run-tests.sh integration
bash scripts/run-tests.sh ui
bash scripts/run-tests.sh dearts
bash scripts/run-tests.sh coverage
bash scripts/run-tests.sh all
```

The UI runner resets and boots an `iPhone 17 Pro Max` simulator automatically and then targets it by UDID for stability.

## Workspace Tasks

The workspace also defines task-based entry points:

- `Xcode Build`
- `Run Simulator (iPhone 17 Pro Max)`
- `DeArtsWCS Unit+Integration`
- `DeArtsWCS UI Flows`
- `DeArtsWCS Full Test Sweep`

Use these when you want repeatable IDE-triggered execution without manually typing the shell commands.

## CI Gates

The current repo-aligned GitHub Actions workflows are:

- `.github/workflows/testing-gates.yml`
- `.github/workflows/dearts-tests.yml`

`testing-gates.yml` is the main quality gate:

- runs unit tests on pull requests and release-related pushes
- runs integration tests on pull requests and release-related pushes
- runs a transitional contract-boundary gate using the integration suite
- runs UI smoke tests on pushes to `master` and `release/**`

`dearts-tests.yml` is the focused DeArtsWCS workflow and executes:

```bash
bash scripts/run-tests.sh dearts
```

An additional broader workflow exists at `.github/workflows/ci-tests.yml`, but the shell-runner-based gates above are the ones currently aligned with the repository test script.

## Coverage And Quality Expectations

Initial goals:

- critical logic: 80%+
- view-model and presentation logic: 70%+
- critical UI flows: small but stable smoke coverage
- crash-free behavior: release gating priority

Coverage is useful, but not sufficient by itself. Prioritize strong coverage on domain logic, mapping, and failure behavior over broad but shallow line execution.

## Debugging Failed Tests

### General Approach

1. Reproduce the failure with the smallest runnable scope.
2. Read the corresponding log in `build/test-results/`.
3. Inspect the `.xcresult` bundle for screenshots, failures, and diagnostics.
4. Fix the root cause instead of retrying or adding sleeps.

### Useful Commands

Run a single XCTest class directly:

```bash
xcodebuild test \
  -project GeoWCS.xcodeproj \
  -scheme GeoWCS \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -only-testing:GeoWCSTests/SafetyEngineTests
```

Run a single UI test class directly:

```bash
xcodebuild test \
  -project GeoWCS.xcodeproj \
  -scheme GeoWCS \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -only-testing:GeoWCSUITests/GeoWCSCriticalFlowsUITests
```

Inspect simulator app data when needed:

```bash
xcrun simctl get_app_container booted com.wcs.GeoWCS data
```

### UI Failures

When UI tests fail:

- check the result bundle for screenshots
- verify accessibility identifiers and waits
- confirm the simulator was reset cleanly
- prefer explicit waits and expectations over hardcoded timing

Do not fix flaky UI tests by increasing arbitrary sleeps unless there is no stable synchronization point.

## Best Practices

Do:

- keep tests isolated
- use descriptive names
- create fresh systems under test
- use protocol seams for external dependencies
- verify behavior, not implementation details
- add one regression test for each production bug
- prefer expectations to raw sleeps

Do not:

- move logic-heavy coverage into UI tests
- allow real network calls in routine tests
- depend on shared mutable state
- test private methods directly
- accept flakiness as normal
- create giant all-purpose mocks

## Example Workflow For New Features

1. Start with one failing test for user-visible behavior or core logic.
2. Implement the smallest production change to pass.
3. Add integration coverage at boundaries if the feature touches persistence, location, media, or remote services.
4. Add UI coverage only if the journey is release-critical.
5. Refactor while keeping the suite green.

## Troubleshooting Notes

| Issue | Preferred response |
|---|---|
| Tests pass locally but fail in CI | Check simulator state, result bundles, and hidden ordering dependencies |
| Flaky UI tests | Replace timing assumptions with waits or better app state hooks |
| Slow test runs | Keep business logic in unit tests and trim unnecessary UI coverage |
| Permission-related failures | Reset simulator state and verify launch configuration |
| Boundary failures | Add or tighten contract-boundary coverage instead of assuming backend behavior |

## Resources

- Apple XCTest documentation
- Apple XCUITest documentation
- `TESTING_FUSION_HANDBOOK.md`
- `scripts/run-tests.sh`

## Support

For testing issues, open a repository issue tagged for testing work and include:

- failing command or workflow
- affected test file or suite
- relevant log excerpt or `.xcresult` context
- whether the failure reproduces locally and in CI