//
//  EmotionalSafetyTests.swift
//  DementiaMediaTests – Quality Suite
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Verifies that the application never startles, distresses, or
//  confuses a patient with inappropriate audio, wording, or UI
//  patterns that require emotional safety policies to prevent.
//

import XCTest
@testable import DementiaMedia

final class EmotionalSafetyTests: XCTestCase {

    private let policy = EmotionalSafetyPolicy.gentle

    // MARK: - No sudden autoplay (1.5 s minimum silence)

    func testMinimumAutoplaySilenceIsOnePointFiveSeconds() {
        XCTAssertGreaterThanOrEqual(policy.minimumAutoplaySilenceSeconds, 1.5,
            "The app must pause for at least 1.5 s before any audio auto-plays")
    }

    func testAutoplaySilenceIsNotMoreThanFiveSeconds() {
        // An excessively long silence also harms experience; upper bound check.
        XCTAssertLessThanOrEqual(policy.minimumAutoplaySilenceSeconds, 5.0,
            "Autoplay silence must not exceed 5 s to avoid appearing frozen")
    }

    // MARK: - No alarming sounds

    func testAlarmTonesAreForbidden() {
        XCTAssertTrue(policy.forbidAlarmTones,
            "The gentle policy must absolutely prohibit alarm-tone sounds")
    }

    // MARK: - Gentle confirmations for destructive actions

    func testDeleteRequiresConfirmation() {
        XCTAssertTrue(policy.requireDeleteConfirmation,
            "Deleting media must always present a confirmation to avoid accidental loss")
    }

    func testPrivacyPolicyAlsoRequiresDeleteConfirmation() {
        let privacyPolicy = PrivacyConsentPolicy.standard
        XCTAssertTrue(privacyPolicy.requiresDeletionConfirmation,
            "Privacy policy must also mandate a deletion confirmation step")
    }

    // MARK: - Activity session emotional pacing

    func testFatiguePolicyEnablesAutoBreakByDefault() {
        let std = FatiguePacingPolicy.standard
        XCTAssertTrue(std.enforceAutoBreak,
            "Standard pacing must enforce automatic rest breaks to prevent emotional fatigue")
    }

    func testAutoBreakIntervalIsHumane() {
        let std = FatiguePacingPolicy.standard
        XCTAssertGreaterThanOrEqual(std.restIntervalSeconds, 5,
            "Auto-break rest interval must be at least 5 s — enough for a patient to relax")
    }

    func testRelaxedPacingHasFasterBreaks() {
        let relaxed  = FatiguePacingPolicy.relaxed
        let standard = FatiguePacingPolicy.standard
        XCTAssertLessThan(relaxed.maxStepsPerBlock, standard.maxStepsPerBlock,
            "Relaxed pacing must offer more frequent breaks than standard for higher-need patients")
    }

    // MARK: - No dead-end permission recovery states

    func testAbandonedSessionIsTerminalSoUICanEscape() {
        var session = ActivitySession(
            prompt: ActivityPrompt(authorID: UUID(), title: "T", bodyText: "B", modality: .text),
            patientID: UUID(),
            pacingPolicy: .standard
        )
        session.start()
        session.abandon()
        XCTAssertTrue(session.isTerminal,
            "Abandoned session must be terminal so the UI can safely navigate away")
    }

    // MARK: - SpeechPrompt policy (no jarring speech)

    func testSpeechPromptModalityExists() {
        let prompt = ActivityPrompt(authorID: UUID(), title: "T",
                                   bodyText: "Listen to this.", modality: .audio)
        XCTAssertEqual(prompt.modality, .audio,
            "Speech prompts must use the .audio modality to trigger calm voice synthesis")
    }
}
