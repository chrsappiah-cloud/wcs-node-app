#!/bin/bash
#
# run-tests.sh
# GeoWCS Testing Suite Runner
# 
# Copyright © 2026 World Class Scholars. All rights reserved.
# Developed under the leadership of Dr. Christopher Appiah-Thompson
#
# Run XCTest suite with configurable test layers
# Usage: ./run-tests.sh [unit|integration|ui|dearts|all|coverage]

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_PATH="${PROJECT_PATH:-/Applications/GeoWCS/GeoWCS.xcodeproj}"
SCHEME="GeoWCS"
CONFIGURATION="Debug"
DEVICE="iPhone 17 Pro Max"
PLATFORM="iOS Simulator"
DESTINATION="platform=$PLATFORM,name=$DEVICE"
UI_TEST_DESTINATION="$DESTINATION"  # overridden by prepare_simulator with stable UDID
DERIVED_DATA_PATH="build/DerivedData"
TEST_LOG_PATH="build/test-results"
COVERAGE_REPORT_PATH="build/coverage"

# Test types
TEST_TYPE="${1:-all}"
COVERAGE_ENABLED="NO"

# Functions
print_header() {
    echo -e "${BLUE}===================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

setup_environment() {
    print_header "Setting up test environment"
    
    # Create output directories
    mkdir -p "$DERIVED_DATA_PATH"
    mkdir -p "$TEST_LOG_PATH"
    mkdir -p "$COVERAGE_REPORT_PATH"
    
    # Clean previous builds if needed
    if [[ "${CLEAN_BUILD:-false}" == "true" ]]; then
        print_warning "Cleaning build artifacts..."
        rm -rf "$DERIVED_DATA_PATH"
        mkdir -p "$DERIVED_DATA_PATH"
    fi
    
    print_success "Environment ready"
}

run_unit_tests() {
    print_header "Running Unit Tests"
    rm -rf "$TEST_LOG_PATH/UnitTests.xcresult"
    
    xcodebuild test \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -destination "$DESTINATION" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -only-testing:GeoWCSTests/CheckInTimerTests \
        -only-testing:GeoWCSTests/SafetyEngineTests \
        -enableCodeCoverage "$COVERAGE_ENABLED" \
        -resultBundlePath "$TEST_LOG_PATH/UnitTests.xcresult" \
        2>&1 | tee "$TEST_LOG_PATH/unit-tests.log" || {
            print_error "Unit tests failed"
            return 1
        }
    
    print_success "Unit tests completed"
}

run_integration_tests() {
    print_header "Running Integration Tests"
    rm -rf "$TEST_LOG_PATH/IntegrationTests.xcresult"
    
    xcodebuild test \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -destination "$DESTINATION" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -only-testing:GeoWCSTests/TrackerIntegrationTests \
        -enableCodeCoverage "$COVERAGE_ENABLED" \
        -resultBundlePath "$TEST_LOG_PATH/IntegrationTests.xcresult" \
        2>&1 | tee "$TEST_LOG_PATH/integration-tests.log" || {
            print_error "Integration tests failed"
            return 1
        }
    
    print_success "Integration tests completed"
}

run_ui_tests() {
    print_header "Running UI Tests"
    
    # Ensure simulator is ready
    prepare_simulator
    rm -rf "$TEST_LOG_PATH/UITests.xcresult"
    
    xcodebuild test \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -destination "$UI_TEST_DESTINATION" \
        -only-testing:GeoWCSUITests \
        -parallel-testing-enabled NO \
        -maximum-parallel-testing-workers 1 \
        -enableCodeCoverage "$COVERAGE_ENABLED" \
        -resultBundlePath "$TEST_LOG_PATH/UITests.xcresult" \
        2>&1 | tee "$TEST_LOG_PATH/ui-tests.log" || {
            print_error "UI tests failed"
            return 1
        }
    
    print_success "UI tests completed"
}

run_dearts_tests() {
    print_header "Running DeArtWCS Focused Test Sweep"
    rm -rf "$TEST_LOG_PATH/DeArtsTests.xcresult"

    xcodebuild test \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -destination "$DESTINATION" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -only-testing:GeoWCSTests/DeArtsWCSTDDScaffoldTests \
        -only-testing:GeoWCSTests/DeArtsWCSAppTypesScaffoldTests \
        -only-testing:GeoWCSTests/DeArtsWCSSeedModeIntegrationTests \
        -only-testing:GeoWCSUITests/DeArtsWCSCriticalFlowsUITests \
        -enableCodeCoverage "$COVERAGE_ENABLED" \
        -resultBundlePath "$TEST_LOG_PATH/DeArtsTests.xcresult" \
        2>&1 | tee "$TEST_LOG_PATH/dearts-tests.log" || {
            print_error "DeArtWCS test sweep failed"
            return 1
        }

    print_success "DeArtWCS focused tests completed"
}

prepare_simulator() {
    print_header "Preparing iOS Simulator"

    # Resolve the UDID of the first available "iPhone 17 Pro Max" simulator
    local sim_udid
    sim_udid=$(xcrun simctl list devices available -j \
        | python3 -c "
import json,sys
d=json.load(sys.stdin)
for rname,devices in d['devices'].items():
    for dev in devices:
        if dev['name'] == 'iPhone 17 Pro Max' and dev.get('isAvailable', False):
            print(dev['udid'])
            exit()
" 2>/dev/null || true)

    if [[ -z "$sim_udid" ]]; then
        print_error "Could not find an available iPhone 17 Pro Max simulator"
        return 1
    fi

    print_warning "Resetting simulator $sim_udid to clear stale state..."
    xcrun simctl shutdown "$sim_udid" 2>/dev/null || true
    sleep 1
    xcrun simctl erase "$sim_udid"
    sleep 2
    xcrun simctl boot "$sim_udid"

    # Wait until the simulator reaches Booted state (up to 60s)
    local attempts=0
    while [[ $attempts -lt 30 ]]; do
        local state
        state=$(xcrun simctl list devices -j \
            | python3 -c "
import json,sys
d=json.load(sys.stdin)
for rname,devices in d['devices'].items():
    for dev in devices:
        if dev['udid'] == '$sim_udid':
            print(dev['state'])
            exit()
" 2>/dev/null || echo "Unknown")
        if [[ "$state" == "Booted" ]]; then
            break
        fi
        sleep 2
        attempts=$((attempts + 1))
    done

    if [[ $attempts -ge 30 ]]; then
        print_error "Simulator $sim_udid did not boot within 60s"
        return 1
    fi

    # Export stable UDID-based destination for UI tests
    UI_TEST_DESTINATION="id=$sim_udid"
    print_success "Simulator $sim_udid ready"
}

generate_coverage_report() {
    print_header "Generating Code Coverage Report"
    
    if [[ ! -f "$DERIVED_DATA_PATH/Index.noindex/Build/Intermediates.noindex/GeneratedModuleClmap.json" ]]; then
        print_warning "No coverage data available"
        return 0
    fi
    
    # Use xccov to generate coverage report
    local coverage_file="$DERIVED_DATA_PATH/Build/Intermediates.noindex/GeoWCS.build/Debug-iphonesimulator/GeoWCS.build/GeoWCS.coverage"
    
    if [[ -f "$coverage_file" ]]; then
        xcrun xccov view "$coverage_file" > "$COVERAGE_REPORT_PATH/coverage.txt"
        print_success "Coverage report generated: $COVERAGE_REPORT_PATH/coverage.txt"
    fi
}

run_all_tests() {
    local failed=0
    
    print_header "Running Complete Test Suite"
    
    # Run each test type
    if ! run_unit_tests; then
        failed=$((failed + 1))
    fi
    
    if ! run_integration_tests; then
        failed=$((failed + 1))
    fi
    
    if ! run_ui_tests; then
        failed=$((failed + 1))
    fi
    
    if [[ "$COVERAGE_ENABLED" == "YES" ]]; then
        generate_coverage_report
    fi
    
    return $failed
}

run_performance_tests() {
    print_header "Running Performance Tests"
    
    xcodebuild test \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -destination "$DESTINATION" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -resultBundlePath "$TEST_LOG_PATH/PerformanceTests.xcresult" \
        2>&1 | tee "$TEST_LOG_PATH/performance-tests.log" || {
            print_error "Performance tests failed"
            return 1
        }
    
    print_success "Performance tests completed"
}

lint_code() {
    print_header "Running Code Linting"
    
    # SwiftLint if available
    if command -v swiftlint &> /dev/null; then
        swiftlint lint --strict 2>&1 | tee "$TEST_LOG_PATH/lint.log" || {
            print_warning "SwiftLint found issues"
        }
    else
        print_warning "SwiftLint not installed, skipping..."
    fi
}

_extract_test_count() {
    # Count "Test case '...' passed/failed" lines emitted by modern xcodebuild.
    # Use awk so zero matches does not fail under set -e + pipefail.
    local log="$1"
    [[ -f "$log" ]] || { echo "0"; return; }
    awk 'BEGIN { c=0 }
         /^Test [Cc]ase '\''.*'\'' (passed|failed)/ { c++ }
         END { print c }' "$log"
}

print_summary() {
    print_header "Test Summary"

    local unit_count integration_count ui_count
    local dearts_count
    unit_count=$(_extract_test_count "$TEST_LOG_PATH/unit-tests.log")
    integration_count=$(_extract_test_count "$TEST_LOG_PATH/integration-tests.log")
    ui_count=$(_extract_test_count "$TEST_LOG_PATH/ui-tests.log")
    dearts_count=$(_extract_test_count "$TEST_LOG_PATH/dearts-tests.log")

    print_success "Unit tests:        $unit_count tests"
    print_success "Integration tests: $integration_count tests"
    print_success "UI tests:          $ui_count tests"
    print_success "DeArtWCS tests:    $dearts_count tests"

    echo ""
    echo "Logs available at: $TEST_LOG_PATH"
    echo "Coverage reports: $COVERAGE_REPORT_PATH"
}

# Main execution
main() {
    case "$TEST_TYPE" in
        unit)
            setup_environment
            lint_code
            run_unit_tests
            ;;
        integration)
            setup_environment
            run_integration_tests
            ;;
        ui)
            setup_environment
            run_ui_tests
            ;;
        dearts)
            setup_environment
            run_dearts_tests
            ;;
        coverage)
            COVERAGE_ENABLED="YES"
            setup_environment
            run_all_tests
            generate_coverage_report
            ;;
        performance)
            setup_environment
            run_performance_tests
            ;;
        all|*)
            setup_environment
            lint_code
            run_all_tests
            ;;
    esac
    
    local exit_code=$?
    
    print_summary
    
    if [[ $exit_code -eq 0 ]]; then
        print_success "All tests passed! ✓"
    else
        print_error "Some tests failed ✗"
    fi
    
    return $exit_code
}

# Run main
main "$@"
