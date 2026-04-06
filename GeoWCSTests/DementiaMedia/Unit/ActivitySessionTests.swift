//
//  ActivitySessionTests.swift
//  DementiaMediaTests – Unit
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Fast, isolated tests for ActivitySession and ActivityStep domain logic.
//

import XCTest
@testable import DementiaMedia

final class ActivitySessionTests: XCTestCase {

    // MARK: - Helpers

    private func makeStep(
        instruction: String = "Do something",
        estimatedSeconds: Double = 60,
        skippable: Bool = true
    ) -> ActivityStep {
        ActivityStep(
            instruction: instruction,
            estimatedDurationSeconds: estimatedSeconds,
            caregiverSkippable: skippable
        )
    }

    private func makeSession(steps: [ActivityStep], policy: FatiguePacingPolicy = .standard) -> ActivitySession {
        ActivitySession(
            patientID: UUID(),
            promptTitle: "Test Activity",
            steps: steps,
            pacingPolicy: policy
        )
    }

    // MARK: - Initial state

    func testNewSessionHasNotStartedState() {
        let session = makeSession(steps: [makeStep()])
        XCTAssertEqual(session.state, .notStarted)
    }

    func testNewSessionCurrentStepIndexIsZero() {
        let session = makeSession(steps: [makeStep(), makeStep()])
        XCTAssertEqual(session.currentStepIndex, 0)
    }

    func testNewSessionAllStepsPending() {
        let session = makeSession(steps: [makeStep(), makeStep(), makeStep()])
        XCTAssertTrue(session.steps.allSatisfy { $0.state == .pending })
    }

    // MARK: - Start

    func testStartTransitionsToInProgress() {
        var session = makeSession(steps: [makeStep()])
        session.start()
        XCTAssertEqual(session.state, .inProgress)
    }

    func testStartSetsFirstStepToActive() {
        var session = makeSession(steps: [makeStep(), makeStep()])
        session.start()
        XCTAssertEqual(session.steps[0].state, .active)
        XCTAssertEqual(session.steps[1].state, .pending)
    }

    func testStartIgnoredIfAlreadyInProgress() {
        var session = makeSession(steps: [makeStep()])
        session.start()
        session.start()  // second call should be a no-op
        XCTAssertEqual(session.state, .inProgress)
    }

    // MARK: - Step completion

    func testCompleteStepAdvancesIndex() {
        var session = makeSession(steps: [makeStep(), makeStep()])
        session.start()
        session.completeCurrentStep()
        XCTAssertEqual(session.currentStepIndex, 1)
    }

    func testCompleteStepMarksStepCompleted() {
        var session = makeSession(steps: [makeStep(), makeStep()])
        session.start()
        session.completeCurrentStep()
        XCTAssertEqual(session.steps[0].state, .completed)
    }

    func testCompletingAllStepsMarkSessionCompleted() {
        var session = makeSession(steps: [makeStep()])
        session.start()
        session.completeCurrentStep()
        XCTAssertEqual(session.state, .completed)
    }

    func testCompletedStepCountAccumulates() {
        var session = makeSession(steps: [makeStep(), makeStep(), makeStep()])
        session.start()
        session.completeCurrentStep()
        session.completeCurrentStep()
        XCTAssertEqual(session.completedStepCount, 2)
    }

    // MARK: - One-step sequencing

    func testCurrentStepReturnsNilAfterCompletion() {
        var session = makeSession(steps: [makeStep()])
        session.start()
        session.completeCurrentStep()
        XCTAssertNil(session.currentStep)
    }

    func testCurrentStepReturnsSecondStepAfterFirst() {
        var session = makeSession(steps: [makeStep(instruction: "First"), makeStep(instruction: "Second")])
        session.start()
        session.completeCurrentStep()
        XCTAssertEqual(session.currentStep?.instruction, "Second")
    }

    // MARK: - Fatigue-aware pacing (auto-break)

    func testAutoBreakTriggeredAfterMaxStepsPerBlock() {
        let policy = FatiguePacingPolicy(restIntervalSeconds: 10, maxStepsPerBlock: 2, enforceAutoBreak: true)
        let steps = (0..<5).map { _ in makeStep() }
        var session = makeSession(steps: steps, policy: policy)
        session.start()
        let break1 = session.completeCurrentStep()
        XCTAssertFalse(break1) // 1st step: no break yet
        let break2 = session.completeCurrentStep()
        XCTAssertTrue(break2)  // 2nd step: break triggered
        XCTAssertEqual(session.state, .pausedForBreak)
    }

    func testAutoBreakResetsBlockCounter() {
        let policy = FatiguePacingPolicy(restIntervalSeconds: 5, maxStepsPerBlock: 1, enforceAutoBreak: true)
        let steps = (0..<3).map { _ in makeStep() }
        var session = makeSession(steps: steps, policy: policy)
        session.start()
        session.completeCurrentStep() // triggers break
        XCTAssertEqual(session.stepsInCurrentBlock, 0)
    }

    func testNoAutoBreakWhenEnforceAutoBreakFalse() {
        let policy = FatiguePacingPolicy(restIntervalSeconds: 5, maxStepsPerBlock: 1, enforceAutoBreak: false)
        let steps = (0..<3).map { _ in makeStep() }
        var session = makeSession(steps: steps, policy: policy)
        session.start()
        let triggered = session.completeCurrentStep()
        XCTAssertFalse(triggered)
        XCTAssertEqual(session.state, .inProgress)
    }

    // MARK: - Resume from break

    func testResumeFromBreakRestoresInProgress() {
        let policy = FatiguePacingPolicy(restIntervalSeconds: 5, maxStepsPerBlock: 1, enforceAutoBreak: true)
        let steps = (0..<3).map { _ in makeStep() }
        var session = makeSession(steps: steps, policy: policy)
        session.start()
        session.completeCurrentStep() // triggers break
        session.resumeFromBreak()
        XCTAssertEqual(session.state, .inProgress)
    }

    func testResumeActivatesNextStep() {
        let policy = FatiguePacingPolicy(restIntervalSeconds: 5, maxStepsPerBlock: 1, enforceAutoBreak: true)
        let steps = (0..<3).map { _ in makeStep() }
        var session = makeSession(steps: steps, policy: policy)
        session.start()
        session.completeCurrentStep()
        session.resumeFromBreak()
        XCTAssertEqual(session.currentStep?.state, .active)
    }

    // MARK: - Caregiver override (skip)

    func testCaregiverCanSkipSkippableStep() {
        var session = makeSession(steps: [makeStep(skippable: true), makeStep()])
        session.start()
        let skipped = session.skipCurrentStep(caregiverID: "carer-001")
        XCTAssertTrue(skipped)
        XCTAssertEqual(session.steps[0].state, .skipped)
    }

    func testCaregiverCannotSkipNonSkippableStep() {
        var session = makeSession(steps: [makeStep(skippable: false), makeStep()])
        session.start()
        let skipped = session.skipCurrentStep(caregiverID: "carer-001")
        XCTAssertFalse(skipped)
        XCTAssertEqual(session.steps[0].state, .active)
    }

    func testCaregiverOverrideIDRecorded() {
        var session = makeSession(steps: [makeStep(), makeStep()])
        session.start()
        session.skipCurrentStep(caregiverID: "carer-007")
        XCTAssertEqual(session.caregiverOverrideID, "carer-007")
    }

    // MARK: - Pause by caregiver

    func testPauseByCaregiver() {
        var session = makeSession(steps: [makeStep(), makeStep()])
        session.start()
        session.pauseByCaregiver()
        XCTAssertEqual(session.state, .pausedByCaregiver)
    }

    func testResumeFromCaregiverPause() {
        var session = makeSession(steps: [makeStep(), makeStep()])
        session.start()
        session.pauseByCaregiver()
        session.resumeFromBreak()
        XCTAssertEqual(session.state, .inProgress)
    }

    // MARK: - Abandonment

    func testAbandonSetsAbandonedState() {
        var session = makeSession(steps: [makeStep(), makeStep()])
        session.start()
        session.abandon()
        XCTAssertEqual(session.state, .abandoned)
    }

    func testAbandonIsIdempotentOnTerminalSession() {
        var session = makeSession(steps: [makeStep()])
        session.start()
        session.completeCurrentStep()
        session.abandon() // already terminal – should not change state
        XCTAssertEqual(session.state, .completed)
    }

    func testIsTerminalTrueForCompletedAndAbandoned() {
        var s1 = makeSession(steps: [makeStep()])
        s1.start(); s1.completeCurrentStep()
        XCTAssertTrue(s1.isTerminal)

        var s2 = makeSession(steps: [makeStep()])
        s2.start(); s2.abandon()
        XCTAssertTrue(s2.isTerminal)
    }

    // MARK: - SessionSummary

    func testSummaryNilBeforeCompletion() {
        var session = makeSession(steps: [makeStep()])
        session.start()
        XCTAssertNil(session.makeSummary())
    }

    func testSummaryCompletionRate100WhenAllCompleted() {
        var session = makeSession(steps: [makeStep(), makeStep()])
        session.start()
        session.completeCurrentStep()
        session.completeCurrentStep()
        let summary = session.makeSummary()
        XCTAssertNotNil(summary)
        XCTAssertEqual(summary!.completionRate, 1.0, accuracy: 0.01)
    }

    func testSummaryCompletionRateReflectsSkippedSteps() {
        var session = makeSession(steps: [makeStep(), makeStep()])
        session.start()
        session.skipCurrentStep(caregiverID: "c1")
        session.completeCurrentStep()
        let summary = session.makeSummary()!
        XCTAssertEqual(summary.completedSteps, 1)
        XCTAssertEqual(summary.skippedSteps, 1)
        XCTAssertEqual(summary.completionRate, 0.5, accuracy: 0.01)
    }

    // MARK: - Repetition intervals (FatiguePacingPolicy)

    func testRepeatIntervalStoredOnPolicy() {
        let policy = FatiguePacingPolicy(restIntervalSeconds: 30, maxStepsPerBlock: 3, enforceAutoBreak: true)
        XCTAssertEqual(policy.restIntervalSeconds, 30)
    }

    // MARK: - Codable round-trip

    func testActivitySessionCodableRoundTrip() throws {
        var session = makeSession(steps: [makeStep(instruction: "Paint a flower"), makeStep(instruction: "Rinse brush")])
        session.start()
        session.completeCurrentStep()

        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(ActivitySession.self, from: data)
        XCTAssertEqual(session, decoded)
    }
}
