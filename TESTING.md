# GeoWCS iOS Testing System

## Overview

GeoWCS implements a comprehensive XCTest/XCUITest testing infrastructure aligned with Apple's native testing ecosystem. This document describes the test strategy, architecture, and execution procedures.

For the unified outside-in + contract-first + XCTest operating model, see `TESTING_FUSION_HANDBOOK.md`.

## Why XCTest/XCUITest?

For native Swift iOS applications, XCTest is the authoritative choice because:

- **Native Integration**: Built into Xcode with zero external dependencies
- **Lower Flakiness**: Direct Framework access vs. black-box approaches (Appium)
- **Performance**: Tests run at full speed with accurate timing
- **Accessibility**: XCUITest uses native accessibility APIs (not DOM-based)
- **CI/CD**: Seamless GitHub Actions, Azure Pipelines, GitLab CI integration
- **Cost**: No per-device licensing or cloud infrastructure required

**When to add Appium**: Only when testing cross-platform device farms or external black-box scenarios; not primary.

## Test Pyramid Architecture

```
           ┌─────────────────┐
           │   UI/E2E Tests  │  ~10 critical flows
           │  (XCUITest)     │  Lower coverage, higher risk
           └─────────────────┘
                  △
                 ╱ ╲
        ┌───────────────────┐
        │ Integration Tests │  ~25 integration scenarios
        │  (XCTest)         │  Subsystem boundaries
        └───────────────────┘
               △
              ╱ ╲
    ┌──────────────────────┐
    │  Unit Tests          │  ~80 unit test cases
    │ (XCTest)             │  Pure logic, fast
    └──────────────────────┘
```

## Test Layers

### 1. Unit Tests (XCTest)

**Location**: `GeoWCSTests/Unit/`

**Focus**: Pure logic with no network, UI, or external dependencies.

**Key Modules**:
- `SafetyEngineTests.swift` (40+ test cases)
  - SOS state transitions
  - Geofence evaluation logic
  - Check-in timer state machine
  - Permission rule evaluation
  - Circle membership rules

- `CheckInTimerTests.swift` (30+ test cases)
  - Timer creation and state management
  - Missed check-in detection
  - Reset and clear operations
  - Persistence and recovery
  - Scheduling and reminders

**Coverage Target**: 80% initial, 90%+ mature

**Run Locally**:
```bash
./scripts/run-tests.sh unit
```

### 2. Integration Tests (XCTest)

**Location**: `GeoWCSTests/Integration/`

**Focus**: Subsystem boundary testing (CLLocationManager → Tracker → ViewModel).

**Key Modules**:
- `TrackerIntegrationTests.swift` (25+ test cases)
  - Location manager → tracker state flow
  - Tracker state → CloudKit sync
  - Geofence events → notifications
  - Background/foreground transitions
  - Offline recovery and relaunch
  - Accuracy filtering and history recording

**Scenarios**:
```
Location Update → Tracker State → ViewModel Update
       ↓              ↓               ↓
    CLLocation    TrackerState    UI Refresh
       ↓              ↓               ↓
    Accuracy      Persistence    New Marker
    Filter        & Sync         on Map
```

**Coverage Target**: 70% initial, 85%+ mature

**Run Locally**:
```bash
./scripts/run-tests.sh integration
```

### 3. UI/E2E Tests (XCUITest)

**Location**: `GeoWCSUITests/`

**Focus**: Highest-risk user flows automated end-to-end.

**Key Flows** (from `GeoWCSCriticalFlowsUITests.swift`):

1. **First Launch Permissions**
   - Location permission alert
   - Notification permission alert
   - Verification of main content

2. **Create Trusted Circle**
   - Circle creation form
   - Member addition with phone validation
   - Circle persistence verification

3. **Start Live Tracking**
   - Navigate to circle
   - Start live tracking
   - Verify map and member locations
   - Verify tracking status UI

4. **Check-In Timer**
   - Arm check-in timer
   - Verify countdown display
   - Simulate missed check-in

5. **SOS Activation**
   - Arm SOS
   - Trigger SOS with long-press
   - Confirm activation dialog
   - Verify emergency notifications

6. **Geofence Creation**
   - Create new geofence
   - Set radius and alerts
   - Save and verify in list

7. **Audio Recording**
   - Start audio recording
   - Verify recording state
   - Stop and playback
   - Share recording

8. **Premium Feature Gating**
   - Verify free features available
   - Attempt premium feature
   - Verify upsell prompt

9. **Background/Foreground**
   - Start tracking in foreground
   - Move to background
   - Return to foreground
   - Verify state recovery

10. **Location History**
    - Navigate to history
    - Verify entries loaded
    - Tap entry for details
    - Verify timestamp and location

**Coverage Target**: Top 10 critical flows, expandable to 20+

**Run Locally**:
```bash
# Requires simulator running
./scripts/run-tests.sh ui
```

## Test Infrastructure

### Directory Structure

```
GeoWCS/
├── GeoWCSTests/
│   ├── Unit/
│   │   ├── SafetyEngineTests.swift
│   │   └── CheckInTimerTests.swift
│   └── Integration/
│       └── TrackerIntegrationTests.swift
├── GeoWCSUITests/
│   └── GeoWCSCriticalFlowsUITests.swift
├── scripts/
│   └── run-tests.sh
├── .github/workflows/
│   └── ci-tests.yml
└── build/
    ├── DerivedData/
    ├── test-results/
    └── coverage/
```

### Test Plans (Xcode)

Each test type is organized in Xcode Test Plans:

- **UnitTests.xctestplan**: Unit test configuration
- **IntegrationTests.xctestplan**: Integration test configuration
- **UITests.xctestplan**: UI test configuration
- **PerformanceTests.xctestplan**: Performance benchmark configuration

### Test Helpers

**Location**: Within each test file

```swift
// SafetyEngine - pure logic implementation
class SafetyEngine { }

// TrackerIntegration - tracker + location manager mock
class TrackerIntegration { }

// MockCLRegion - geofence mocking
class MockCLRegion: CLRegion { }
```

## Running Tests

### Local Execution

**Run all tests**:
```bash
./scripts/run-tests.sh all
```

**Run DeArtWCS focused suite**:
```bash
./scripts/run-tests.sh dearts
```

**Run specific layer**:
```bash
./scripts/run-tests.sh unit          # Unit tests only
./scripts/run-tests.sh integration   # Integration tests only
./scripts/run-tests.sh ui            # UI tests only
./scripts/run-tests.sh dearts        # DeArtWCS-focused tests only
./scripts/run-tests.sh coverage      # All tests + coverage
```

**Run in Xcode**:
```bash
# Product → Test (⌘U)
# Or select specific test class and run
```

**Run on commanded device**:
```bash
./scripts/run-tests.sh ui --device "iPhone SE (3rd generation)"
```

### CI/CD Pipeline

GitHub Actions workflow: `.github/workflows/ci-tests.yml`

DeArtWCS-focused workflow: `.github/workflows/dearts-tests.yml`

### DeArtWCS Focused Suite

The DeArtWCS-focused suite runs a deterministic subset scoped to RokMaxCreative/DeArtsWCS:

- `GeoWCSTests/DeArtsWCSTDDScaffoldTests`
- `GeoWCSTests/DeArtsWCSAppTypesScaffoldTests`
- `GeoWCSTests/DeArtsWCSSeedModeIntegrationTests`
- `GeoWCSUITests/DeArtsWCSCriticalFlowsUITests`

Deterministic UI mode is enabled by launch environment in UI tests:

- `DEARTSWCS_UI_TEST_MODE=1`

This mode seeds stable initial app data for reliable UI assertions.

**Triggers**:
- Push to master/develop/feature/*
- Pull requests to master/develop
- Nightly schedule (2 AM UTC)

**Jobs**:
1. **Lint** - SwiftLint + format checks
2. **Build** - Compile for simulator
3. **Unit Tests** - Run unit test suite
4. **Integration Tests** - Run integration suite
5. **UI Tests** - Run critical flows
6. **Coverage** - Generate coverage report
7. **Performance** - Nightly benchmarks
8. **Security** - SwiftLint security rules + secret scanning
9. **Test Report** - Summary and artifact collection
10. **Release Gate** - Final checks for master branch

#### CI Pipeline Execution

```
Push to master/develop
       ↓
[Lint] → [Build] → ┬─→ [Unit Tests]
                   ├─→ [Integration Tests]
                   └─→ [UI Tests]
                         ↓
                   [Coverage Report]
                         ↓
                   [Security Scan]
                         ↓
                   [Test Summary]
                         ↓
                   [Release Gate] (master only)
```

**Estimated Run Time**: 
- PR builds: ~15 minutes (unit + integration + critical UI tests)
- Nightly: ~30 minutes (full suite + performance + extended UI tests)

## Coverage Goals

| Category | Initial | Mature |
|----------|---------|--------|
| Critical Logic | 80%+ | 90%+ |
| View Models | 70%+ | 85%+ |
| UI Flows | 10 flows | 20 flows |
| Crash-Free | 99.5%+ | 99.8%+ |

**Critical logic** includes:
- Safety rule evaluation
- SOS state transitions
- Geofence math
- Permission mapping
- Timer state machine
- Phone validation

## Performance Benchmarks

Performance tests run nightly in `PerformanceTests.xctestplan`:

- **App Launch**: < 2.0 seconds
- **Map Render**: < 500ms
- **Location Update**: < 100ms latency
- **History Load**: < 1.0 second (500 entries)
- **Geofence Calculation**: < 50ms

## Release Gates

A build must pass ALL gates before shipping:

```
✓ Swift compilation (no errors)
✓ All unit tests GREEN
✓ All integration tests GREEN
✓ Critical UI tests GREEN (simulator)
✓ Code coverage ≥ 80%
✓ No security vulnerabilities
✓ No SwiftLint regressions
✓ Performance within tolerance
```

**Master Branch**: Automatic release gate on push

**Release Candidate**: Manual gate verification before App Store submission

## Debugging Failed Tests

### Unit Test Failures

```bash
# Re-run with verbose logging
xcodebuild test -scheme GeoWCS -testPlan UnitTests -verbose

# Check specific test class
xcodebuild test -scheme GeoWCS -testPlan UnitTests -only-testing "GeoWCSTests/SafetyEngineTests"

# Debug in Xcode
# 1. Open test file
# 2. Click diamond icon next to test
# 3. Click to run with debugger (▶|)
```

### Integration Test Failures

```bash
# Check persistence/storage issues
xcrun simctl get_app_container booted com.wcs.GeoWCS data

# Inspect CloudKit sync state
# Xcode → Schemes → Edit Scheme → Run → Arguments:
# -com.apple.CoreData.ConcurrencyDebug 1
```

### UI Test Failures

```bash
# Take screenshot on failure
xcodebuild test -scheme GeoWCS -testPlan UITests -screenshot-on-failure

# Video recording
xcodebuild test -scheme GeoWCS -testPlan UITests -record-play-back

# Verbose logging
xcodebuild test -scheme GeoWCS -testPlan UITests -verbose -resultBundlePath build/UITests.xcresult

# Check accessibility inspector
# Xcode → Accessibility Inspector (Cmd+Option+Z)
```

## Best Practices

### ✅ Do

- **Isolate tests**: Each test is independent, no shared state
- **Use clear names**: `test_WhenCondition_ThenExpectedResult()`
- **Mock external dependencies**: Network, location, notifications
- **Arrange-Act-Assert**: Setup → Execute → Verify pattern
- **One assertion per happy path**: Easier debugging
- **Test edge cases**: Zero values, negatives, nil, bounds
- **Use snapshot tests**: UI layouts with `XCTestDynamicOverlay`

### ❌ Don't

- **UI tests for all logic**: Keep logic in unit tests
- **Network calls in tests**: Mock with `URLSession.shared` mock
- **Hardcoded waits**: Use `XCTestExpectation` instead
- **Test private methods**: Test public interface
- **Ignore flaky tests**: Fix root cause, don't retry
- **Long async chains**: Break into smaller, mockable units

## Example: Adding a New Test

```swift
// SafetyEngineTests.swift

func testNewSOSFeature() {
    // Arrange
    let engine = SafetyEngine()
    
    // Act
    engine.armSOS()
    
    // Assert
    XCTAssertTrue(engine.isSOSActive)
}
```

Run it:
```bash
xcodebuild test -scheme GeoWCS -testPlan UnitTests \
  -only-testing "GeoWCSTests/SafetyEngineTests/testNewSOSFeature"
```

## Continuous Integration Integration

### GitHub Actions Status Badge

Add to README.md:
```markdown
![CI Tests](https://github.com/[owner]/GeoWCS/actions/workflows/ci-tests.yml/badge.svg)
```

### Pre-commit Hook

```bash
# .git/hooks/pre-commit
#!/bin/bash
./scripts/run-tests.sh unit || exit 1
```

### Release PR Checklist

```markdown
- [ ] All tests passing (CI green)
- [ ] Code coverage ≥ 80%
- [ ] Manual smoke test on device
- [ ] Performance benchmarks reviewed
- [ ] Security scan cleared
```

## Testing Roadmap

### Phase 1 (Current)
- ✅ Unit test foundation (SafetyEngine, CheckInTimer)
- ✅ Integration test foundation (Tracker)
- ✅ Critical UI tests (10 flows)
- ✅ CI/CD pipeline (GitHub Actions)

### Phase 2 (Q2 2026)
- 🔲 Expand UI tests to 20 flows
- 🔲 Add performance regression tracking
- 🔲 Snapshot testing for UI layouts
- 🔲 E2E testing on physical devices

### Phase 3 (Q3 2026)
- 🔲 Appium cloud matrix testing
- 🔲 Android test parity
- 🔲 Load testing with 1000+ users
- 🔲 Security penetration testing

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Tests pass locally, fail in CI | Ensure simulator is warm; add sleep(1) after app launch |
| Flaky UI tests | Use `waitForExistence` instead of assertions; check accessibility |
| Slow test builds | Disable code signing in test scheme; use cache |
| Permission tests fail | Restart simulator; clear app data: `xcrun simctl erase all` |
| CloudKit sync issues | Enable verbose logging; check iCloud credentials in Xcode |

## Resources

- [Apple XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [XCUITest Best Practices](https://developer.apple.com/videos/play/wwdc2021/10208/)
- [GitHub Actions Xcode](https://github.com/marketplace/actions/run-xcodebuild-tests)
- [Fastlane Testing Guide](https://docs.fastlane.tools/actions/scan/)

## Support

For testing questions or issues:
- GitHub Issues: Label with `[testing]`
- Email: dev@worldclassscholars.com
- Slack: #testing channel

---

**Last Updated**: April 2, 2026  
**Version**: 1.0  
**Copyright © 2026 World Class Scholars**
