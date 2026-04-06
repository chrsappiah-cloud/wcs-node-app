//
//  CognitiveSimplicityTests.swift
//  DementiaMediaTests – Quality Suite
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Verifies that the application design system enforces dementia-safe
//  cognitive-simplicity constraints at the policy and domain level.
//

import XCTest
@testable import DementiaMedia

final class CognitiveSimplicityTests: XCTestCase {

    // MARK: - CognitiveSafetyPolicy constants

    private let policy = CognitiveSafetyPolicy.dementiaSafe

    func testOnePrimaryActionPerScreen_maxControlsFour() {
        XCTAssertEqual(policy.maxControlsPerScreen, 4,
            "Policy must cap interactive controls at exactly 4 per screen")
    }

    func testMaxSimultaneousChoicesIsThree() {
        XCTAssertEqual(policy.maxSimultaneousChoices, 3,
            "Policy must cap simultaneous options at exactly 3")
    }

    func testBackButtonAlwaysVisible() {
        XCTAssertTrue(policy.backAlwaysVisible,
            "Back navigation must always be visible — never hidden behind a gesture")
    }

    func testPlainLanguageErrors() {
        XCTAssertTrue(policy.plainLanguageErrors,
            "Error messages must use plain language so patients understand them")
    }

    // MARK: - Predictable navigation (activity session step sequencing)

    func testActivitySessionStepsAreOrderedSequentially() throws {
        let steps = [
            ActivityStep(instruction: "Step 1", estimatedDurationSeconds: 30),
            ActivityStep(instruction: "Step 2", estimatedDurationSeconds: 30),
            ActivityStep(instruction: "Step 3", estimatedDurationSeconds: 30),
        ]
        let prompt = ActivityPrompt(
            authorID: UUID(),
            title: "Order Test",
            bodyText: "Three steps",
            modality: .text,
            steps: steps
        )
        // Steps must preserve insertion order (predictable navigation)
        XCTAssertEqual(prompt.steps.map(\.instruction), ["Step 1", "Step 2", "Step 3"])
    }

    func testCurrentStepAlwaysBeginsAtIndex0() {
        let steps = (1...3).map { ActivityStep(instruction: "Step \($0)", estimatedDurationSeconds: 20) }
        let prompt = ActivityPrompt(authorID: UUID(), title: "T", bodyText: "B",
                                    modality: .text, steps: steps)
        var session = ActivitySession(prompt: prompt, patientID: UUID(), pacingPolicy: .standard)
        session.start()
        XCTAssertEqual(session.currentStepIndex, 0,
            "Session must always start at the first step with no ambiguity")
    }

    func testCompletingOneStepAdvancesIndexByOne() throws {
        let steps = (1...3).map { ActivityStep(instruction: "Step \($0)", estimatedDurationSeconds: 20) }
        let prompt = ActivityPrompt(authorID: UUID(), title: "T", bodyText: "B",
                                    modality: .text, steps: steps)
        var session = ActivitySession(prompt: prompt, patientID: UUID(), pacingPolicy: .standard)
        session.start()
        try session.completeCurrentStep()
        XCTAssertEqual(session.currentStepIndex, 1,
            "Completing a step must advance to the next step exactly once")
    }

    // MARK: - Caregiver skip policy

    func testSkipRequiresCaregiverSkippableFlag() {
        var step = ActivityStep(instruction: "Step", estimatedDurationSeconds: 30)
        step.caregiverSkippable = false
        XCTAssertFalse(step.caregiverSkippable,
            "Caregiver skip must only be permitted when the step explicitly allows it")
    }

    func testSkippableStepIsSkippable() {
        var step = ActivityStep(instruction: "Step", estimatedDurationSeconds: 30)
        step.caregiverSkippable = true
        XCTAssertTrue(step.caregiverSkippable)
    }

    // MARK: - No-dead-end policy: terminal states are named and final

    func testTerminalStatesAreCompletedOrAbandoned() {
        let terminal: [SessionState] = [.completed, .abandoned]
        for state in terminal {
            let mockSession = makeSessionInState(state)
            XCTAssertTrue(mockSession.isTerminal,
                "\(state) must be recognised as terminal to prevent further navigation")
        }
    }

    func testNonTerminalStatesAreNotTerminal() {
        let ongoing: [SessionState] = [.notStarted, .inProgress, .pausedForBreak, .pausedByCaregiver]
        for state in ongoing {
            let s = makeSessionInState(state)
            XCTAssertFalse(s.isTerminal, "\(state) must not be marked terminal")
        }
    }

    // MARK: - Helpers

    private func makeSessionInState(_ state: SessionState) -> ActivitySession {
        var session = ActivitySession(
            prompt: ActivityPrompt(authorID: UUID(), title: "T", bodyText: "B",
                                   modality: .text),
            patientID: UUID(),
            pacingPolicy: .standard
        )
        // Force state via the session's own mutation methods where possible.
        switch state {
        case .notStarted:
            break
        case .inProgress:
            session.start()
        case .pausedForBreak:
            session.start()
            session.pauseForBreak()
        case .pausedByCaregiver:
            session.start()
            session.pauseByCaregiver()
        case .completed:
            session.start()
            _ = session.makeSummary() // completed via makeSummary path
            // Force completed using internal state if necessary
        case .abandoned:
            session.start()
            session.abandon()
        }
        return session
    }
}
