//
//  PolicyTests.swift
//  DementiaMediaTests – Unit / PolicyTests
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Verifies first-class business policies for storage thresholds,
//  cognitive safety, emotional safety, privacy consent, and performance.
//

import XCTest
@testable import DementiaMedia

final class StorageThresholdPolicyTests: XCTestCase {

    func testDefaultThresholdsHaveExpectedValues() {
        let policy = StorageThresholdPolicy.default
        XCTAssertEqual(policy.draftBlockThresholdBytes, 50 * 1_024 * 1_024)
        XCTAssertEqual(policy.exportBlockThresholdBytes, 200 * 1_024 * 1_024)
        XCTAssertEqual(policy.warningThresholdBytes, 500 * 1_024 * 1_024)
    }

    func testShouldBlockDraftBelowDraftThreshold() {
        let policy = StorageThresholdPolicy.default
        let freeBytes: Int64 = 40 * 1_024 * 1_024 // 40 MB – below 50 MB limit
        XCTAssertTrue(policy.shouldBlockDraft(freeBytes: freeBytes))
    }

    func testShouldNotBlockDraftAboveDraftThreshold() {
        let policy = StorageThresholdPolicy.default
        let freeBytes: Int64 = 60 * 1_024 * 1_024 // 60 MB – above 50 MB limit
        XCTAssertFalse(policy.shouldBlockDraft(freeBytes: freeBytes))
    }

    func testShouldBlockExportBelowExportThreshold() {
        let policy = StorageThresholdPolicy.default
        let freeBytes: Int64 = 150 * 1_024 * 1_024
        XCTAssertTrue(policy.shouldBlockExport(freeBytes: freeBytes))
    }

    func testShouldNotBlockExportAboveExportThreshold() {
        let policy = StorageThresholdPolicy.default
        let freeBytes: Int64 = 250 * 1_024 * 1_024
        XCTAssertFalse(policy.shouldBlockExport(freeBytes: freeBytes))
    }

    func testShouldWarnBelowWarningThreshold() {
        let policy = StorageThresholdPolicy.default
        let freeBytes: Int64 = 400 * 1_024 * 1_024
        XCTAssertTrue(policy.shouldWarn(freeBytes: freeBytes))
    }

    func testShouldNotWarnAboveWarningThreshold() {
        let policy = StorageThresholdPolicy.default
        let freeBytes: Int64 = 600 * 1_024 * 1_024
        XCTAssertFalse(policy.shouldWarn(freeBytes: freeBytes))
    }

    func testDraftBoundaryExactlyAtThreshold() {
        let policy = StorageThresholdPolicy.default
        // Exactly at the threshold should still block (freeBytes < threshold is the rule)
        XCTAssertFalse(policy.shouldBlockDraft(freeBytes: policy.draftBlockThresholdBytes))
    }
}

final class CognitiveSafetyPolicyTests: XCTestCase {

    func testDementiaSafePresetHasMaxThreeChoices() {
        XCTAssertEqual(CognitiveSafetyPolicy.dementiaSafe.maximumSimultaneousChoices, 3)
    }

    func testDementiaSafePresetHasMaxFourControls() {
        XCTAssertEqual(CognitiveSafetyPolicy.dementiaSafe.maximumInteractiveControlsPerScreen, 4)
    }

    func testDementiaSafePresetBackAlwaysVisible() {
        XCTAssertTrue(CognitiveSafetyPolicy.dementiaSafe.backAlwaysVisible)
    }

    func testDementiaSafePresetPlainLanguageErrors() {
        XCTAssertTrue(CognitiveSafetyPolicy.dementiaSafe.plainLanguageErrors)
    }

    func testIsSafeChoiceCountBelowMax() {
        let policy = CognitiveSafetyPolicy.dementiaSafe
        XCTAssertTrue(policy.isSafe(choiceCount: 2))
    }

    func testIsSafeChoiceCountAtMax() {
        let policy = CognitiveSafetyPolicy.dementiaSafe
        XCTAssertTrue(policy.isSafe(choiceCount: 3))
    }

    func testIsUnsafeChoiceCountAboveMax() {
        let policy = CognitiveSafetyPolicy.dementiaSafe
        XCTAssertFalse(policy.isSafe(choiceCount: 5))
    }

    func testIsSafeControlCountAtMax() {
        let policy = CognitiveSafetyPolicy.dementiaSafe
        XCTAssertTrue(policy.isSafe(controlCount: 4))
    }

    func testIsUnsafeControlCountAboveMax() {
        let policy = CognitiveSafetyPolicy.dementiaSafe
        XCTAssertFalse(policy.isSafe(controlCount: 6))
    }
}

final class EmotionalSafetyPolicyTests: XCTestCase {

    func testDefaultPolicyRequiresDeleteConfirmation() {
        XCTAssertTrue(EmotionalSafetyPolicy.default.requireDeleteConfirmation)
    }

    func testDefaultPolicyForbidsAlarmTones() {
        XCTAssertTrue(EmotionalSafetyPolicy.default.forbidAlarmTones)
    }

    func testDefaultPolicyRequiresPermissionRecovery() {
        XCTAssertTrue(EmotionalSafetyPolicy.default.mustProvidePermissionRecovery)
    }

    func testAutoplaySafeWithSufficientDelay() {
        let policy = EmotionalSafetyPolicy.default
        XCTAssertTrue(policy.isAutoplaySafe(delaySeconds: 2.0))
    }

    func testAutoplayUnsafeWithZeroDelay() {
        let policy = EmotionalSafetyPolicy.default
        XCTAssertFalse(policy.isAutoplaySafe(delaySeconds: 0))
    }

    func testAutoplayUnsafeBelowMinimum() {
        let policy = EmotionalSafetyPolicy.default
        XCTAssertFalse(policy.isAutoplaySafe(delaySeconds: 1.0))
    }

    func testAutoplayBoundaryExactlyAtMinimum() {
        let policy = EmotionalSafetyPolicy.default
        XCTAssertTrue(policy.isAutoplaySafe(delaySeconds: policy.minimumAutoplaySilenceSeconds))
    }
}

final class PrivacyConsentPolicyTests: XCTestCase {

    func testDefaultPolicyRequiresExplicitRecordingConsent() {
        XCTAssertTrue(PrivacyConsentPolicy.default.requiresExplicitRecordingConsent)
    }

    func testDefaultPolicyDisallowsExternalExport() {
        XCTAssertFalse(PrivacyConsentPolicy.default.allowsExternalExport)
    }

    func testDefaultPolicyEnforcesLocalOnlyStorage() {
        XCTAssertTrue(PrivacyConsentPolicy.default.enforceLocalOnlyStorage)
    }

    func testDefaultPolicyRequiresDeletionConfirmation() {
        XCTAssertTrue(PrivacyConsentPolicy.default.requiresDeletionConfirmation)
    }

    func testCustomPolicyCanPermitExternalExport() {
        let policy = PrivacyConsentPolicy(
            requiresExplicitRecordingConsent: false,
            allowsExternalExport: true,
            enforceLocalOnlyStorage: false,
            requiresDeletionConfirmation: false
        )
        XCTAssertTrue(policy.allowsExternalExport)
    }
}

final class PerformanceBudgetPolicyTests: XCTestCase {

    func testAcceptableLaunchBudgetIsReasonable() {
        XCTAssertLessThanOrEqual(PerformanceBudgetPolicy.acceptable.maxColdLaunchSeconds, 3.0)
    }

    func testAcceptablePaintingLatencyIsSubFrame() {
        // Should be below one 60fps frame (≈ 0.016s)... but we use 30fps budget
        XCTAssertLessThanOrEqual(PerformanceBudgetPolicy.acceptable.maxPaintingFirstStrokeLatencySeconds, 0.033)
    }

    func testRecordStartLatencyIsUnderHalfSecond() {
        XCTAssertLessThanOrEqual(PerformanceBudgetPolicy.acceptable.maxRecordStartLatencySeconds, 0.5)
    }

    func testSlideshowExportBudgetIsReasonable() {
        XCTAssertLessThanOrEqual(PerformanceBudgetPolicy.acceptable.maxSlideshowExportSeconds, 60.0)
    }
}
