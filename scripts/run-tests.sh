#!/bin/bash
#
# run-tests.sh
# GeoWCS Testing Suite Runner
# 
# Copyright © 2026 World Class Scholars. All rights reserved.
# Developed under the leadership of Dr. Christopher Appiah-Thompson
#
# Run XCTest suite with configurable test layers
# Usage: ./run-tests.sh [unit|integration|ui|all|coverage]

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT="GeoWCS"
SCHEME="GeoWCS"
CONFIGURATION="Debug"
DEVICE="iPhone 17 Pro Max"
PLATFORM="iOS Simulator"
DERIVED_DATA_PATH="build/DerivedData"
TEST_LOG_PATH="build/test-results"
COVERAGE_REPORT_PATH="build/coverage"

# Test types
TEST_TYPE="${1:-all}"
COVERAGE_ENABLED=false

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
    
    xcodebuild test \
        -project "$PROJECT.xcodeproj" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -testPlan "UnitTests" \
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
    
    xcodebuild test \
        -project "$PROJECT.xcodeproj" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -testPlan "IntegrationTests" \
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
    
    xcodebuild test \
        -project "$PROJECT.xcodeproj" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -destination "platform=$PLATFORM,name=$DEVICE" \
        -testPlan "UITests" \
        -enableCodeCoverage "$COVERAGE_ENABLED" \
        -resultBundlePath "$TEST_LOG_PATH/UITests.xcresult" \
        2>&1 | tee "$TEST_LOG_PATH/ui-tests.log" || {
            print_error "UI tests failed"
            return 1
        }
    
    print_success "UI tests completed"
}

prepare_simulator() {
    print_header "Preparing iOS Simulator"
    
    # Boot simulator if needed
    xcrun simctl boot "$DEVICE" 2>/dev/null || true
    sleep 3
    
    print_success "Simulator ready"
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
    
    if [[ "$COVERAGE_ENABLED" == "true" ]]; then
        generate_coverage_report
    fi
    
    return $failed
}

run_performance_tests() {
    print_header "Running Performance Tests"
    
    xcodebuild test \
        -project "$PROJECT.xcodeproj" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -testPlan "PerformanceTests" \
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

print_summary() {
    print_header "Test Summary"
    
    if [[ -f "$TEST_LOG_PATH/unit-tests.log" ]]; then
        local unit_count=$(grep -c "Test Case" "$TEST_LOG_PATH/unit-tests.log" || echo "0")
        print_success "Unit tests: $unit_count tests"
    fi
    
    if [[ -f "$TEST_LOG_PATH/integration-tests.log" ]]; then
        local integration_count=$(grep -c "Test Case" "$TEST_LOG_PATH/integration-tests.log" || echo "0")
        print_success "Integration tests: $integration_count tests"
    fi
    
    if [[ -f "$TEST_LOG_PATH/ui-tests.log" ]]; then
        local ui_count=$(grep -c "Test Case" "$TEST_LOG_PATH/ui-tests.log" || echo "0")
        print_success "UI tests: $ui_count tests"
    fi
    
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
            prepare_simulator
            run_ui_tests
            ;;
        coverage)
            COVERAGE_ENABLED=true
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
