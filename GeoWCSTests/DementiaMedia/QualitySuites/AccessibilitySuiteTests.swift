//
//  AccessibilitySuiteTests.swift
//  DementiaMediaTests – Quality Suite
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  First-class dementia accessibility quality suite.
//  Tests assert against design-system constants so any regression in
//  accessibility tokens fails a clear, labelled test.
//

import XCTest
@testable import DementiaMedia

final class AccessibilitySuiteTests: XCTestCase {

    // MARK: - Minimum Tap-Target Policy (CognitiveSafetyPolicy)

    func testCognitivePolicyMaxControlsIsAtMostFour() {
        let policy = CognitiveSafetyPolicy.dementiaSafe
        XCTAssertLessThanOrEqual(policy.maxControlsPerScreen, 4,
            "No screen should expose more than 4 interactive controls to the patient")
    }

    func testCognitivePolicyMaxChoicesIsAtMostThree() {
        let policy = CognitiveSafetyPolicy.dementiaSafe
        XCTAssertLessThanOrEqual(policy.maxSimultaneousChoices, 3,
            "Choices must not exceed 3 to reduce cognitive load")
    }

    func testBackAlwaysVisibleIsEnforced() {
        let policy = CognitiveSafetyPolicy.dementiaSafe
        XCTAssertTrue(policy.backAlwaysVisible,
            "A back/escape affordance must always be visible to prevent screen traps")
    }

    func testPlainLanguageErrorsEnabled() {
        let policy = CognitiveSafetyPolicy.dementiaSafe
        XCTAssertTrue(policy.plainLanguageErrors,
            "Error messages must use plain language without technical jargon")
    }

    // MARK: - Emotional Safety (autoplay silence)

    func testMinimumAutoplaySilenceSeconds() {
        let policy = EmotionalSafetyPolicy.gentle
        XCTAssertGreaterThanOrEqual(policy.minimumAutoplaySilenceSeconds, 1.5,
            "At least 1.5 s of silence must precede any auto-playing media")
    }

    func testNoAlarmTonesEnabled() {
        let policy = EmotionalSafetyPolicy.gentle
        XCTAssertTrue(policy.forbidAlarmTones,
            "Alarm-style notification sounds must never be used for dementia patients")
    }

    // MARK: - Consent policy

    func testExplicitConsentRequired() {
        let policy = PrivacyConsentPolicy.standard
        XCTAssertTrue(policy.requiresExplicitRecordingConsent,
            "Recording must require explicit opt-in consent every session")
    }

    func testDeleteRequiresConfirmation() {
        let policy = EmotionalSafetyPolicy.gentle
        XCTAssertTrue(policy.requireDeleteConfirmation,
            "Destructive actions must always show a confirmation step")
    }

    // MARK: - Performance budget (launch latency affects accessibility)

    func testLaunchBudgetTwoSeconds() {
        let policy = PerformanceBudgetPolicy.acceptable
        XCTAssertLessThanOrEqual(policy.appLaunchSeconds, 2.0,
            "Cold launch must complete within 2 s to meet accessibility responsiveness standards")
    }

    func testFirstStrokeLatencyBudget() {
        let policy = PerformanceBudgetPolicy.acceptable
        XCTAssertLessThanOrEqual(policy.paintingFirstStrokeSeconds, 0.033,
            "First paint stroke must register within one frame (≤ 33 ms)")
    }

    // MARK: - Activity pacing (cognitive fatigue)

    func testRelaxedPacingPolicyHasShorterStepBlocks() {
        let standard = FatiguePacingPolicy.standard
        let relaxed  = FatiguePacingPolicy.relaxed
        XCTAssertLessThanOrEqual(relaxed.maxStepsPerBlock, standard.maxStepsPerBlock,
            "Relaxed pacing must have equal or fewer steps per block than standard")
    }

    func testStandardPacingRestIntervalIsAtLeastTenSeconds() {
        let policy = FatiguePacingPolicy.standard
        XCTAssertGreaterThanOrEqual(policy.restIntervalSeconds, 10,
            "Standard pacing must provide at least 10 s of rest between blocks")
    }

    // MARK: - MediaAsset accessibility metadata

    func testActivitySessionKindExists() {
        // Ensures the .activitySession kind is present for guided activity flows
        let asset = MediaAsset(title: "Session", ownerID: UUID(), kind: .activitySession)
        XCTAssertEqual(asset.kind, .activitySession)
    }

    func testAllMediaKindsHaveNonEmptyTitle() {
        let kinds: [MediaKind] = [.audioRecording, .painting, .speechPrompt,
                                  .slideshow, .activitySession]
        for kind in kinds {
            let asset = MediaAsset(title: "Test", ownerID: UUID(), kind: kind)
            XCTAssertFalse(asset.title.isEmpty,
                "\(kind) asset must have a non-empty title for screen readers")
        }
    }
}
