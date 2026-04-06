//
//  StartGuidedActivityTests.swift
//  DementiaMediaTests – Unit
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Unit tests for StartGuidedActivity use-case: one-step progression,
//  caregiver override, repeat intervals, completion logic, fatigue
//  pacing, abandon, and session summary generation.
//

import XCTest
@testable import DementiaMedia

final class StartGuidedActivityTests: XCTestCase {

    // MARK: - Helpers

    private var repo: FakeMediaRepository!
    private var scheduler: FakeNotificationScheduler!
    private var analytics: FakeAnalyticsLogger!
    private var sut: StartGuidedActivity!
    private let patientID = UUID()

    override func setUp() {
        super.setUp()
        repo      = FakeMediaRepository()
        scheduler = FakeNotificationScheduler()
        analytics = FakeAnalyticsLogger()
        sut = StartGuidedActivity(
            repository: repo,
            notificationScheduler: scheduler,
            analytics: analytics
        )
    }

    override func tearDown() {
        sut = nil; repo = nil; scheduler = nil; analytics = nil
        super.tearDown()
    }

    private func makePrompt(body: String = "Do step A. Do step B.", minutes: Int = 5) -> ActivityPrompt {
        ActivityPrompt(
            authorID: UUID(),
            title: "Morning Routine",
            bodyText: body,
            estimatedMinutes: minutes,
            modality: .text
        )
    }

    // MARK: - Begin / start

    func testBeginReturnsSessionInInProgressState() async throws {
        let prompt = makePrompt()
        let session = try await sut.begin(prompt: prompt, patientID: patientID)
        XCTAssertEqual(session.state, .inProgress)
    }

    func testBeginPersistsOneAsset() async throws {
        let prompt = makePrompt()
        _ = try await sut.begin(prompt: prompt, patientID: patientID)
        XCTAssertEqual(repo.saveCallCount, 1)
    }

    func testBeginLogsStartedEvent() async throws {
        let prompt = makePrompt()
        _ = try await sut.begin(prompt: prompt, patientID: patientID)
        XCTAssertFalse(analytics.events(named: "activity.started").isEmpty)
    }

    func testBeginCreatesStepsFromPromptChunks() async throws {
        let prompt = makePrompt(body: "First. Second. Third.")
        let session = try await sut.begin(prompt: prompt, patientID: patientID)
        XCTAssertEqual(session.steps.count, 3)
    }

    // MARK: - One-step sequencing

    func testCompleteStepAdvancesToNextStep() async throws {
        var session = try await sut.begin(prompt: makePrompt(body: "A. B."), patientID: patientID)
        try sut.completeStep(in: &session)
        XCTAssertEqual(session.currentStepIndex, 1)
    }

    func testCompleteAllStepsMarkSessionCompleted() async throws {
        var session = try await sut.begin(prompt: makePrompt(body: "Only one."), patientID: patientID)
        try sut.completeStep(in: &session)
        XCTAssertEqual(session.state, .completed)
    }

    func testCompleteStepOnTerminalSessionThrows() async throws {
        var session = try await sut.begin(prompt: makePrompt(body: "One."), patientID: patientID)
        try sut.completeStep(in: &session) // completes session
        XCTAssertThrowsError(try sut.completeStep(in: &session)) { error in
            XCTAssertEqual(error as? GuidedActivityError, .sessionAlreadyTerminal)
        }
    }

    // MARK: - Caregiver override

    func testSkipStepMarksStepSkipped() async throws {
        var session = try await sut.begin(prompt: makePrompt(body: "A. B."), patientID: patientID)
        try sut.skipStep(in: &session, caregiverID: "carer-42")
        XCTAssertEqual(session.steps[0].state, .skipped)
    }

    func testSkipStepLogsEvent() async throws {
        var session = try await sut.begin(prompt: makePrompt(body: "A. B."), patientID: patientID)
        try sut.skipStep(in: &session, caregiverID: "carer-42")
        XCTAssertFalse(analytics.events(named: "activity.step_skipped_by_caregiver").isEmpty)
    }

    func testSkipNonSkippableStepThrows() async throws {
        let prompt = makePrompt(body: "One step only.")
        var session = try await sut.begin(prompt: prompt, patientID: patientID, pacingPolicy: .standard)
        // Force the first step to be non-skippable
        session.steps[0] = ActivityStep(
            id: session.steps[0].id,
            instruction: session.steps[0].instruction,
            caregiverSkippable: false,
            state: .active
        )
        XCTAssertThrowsError(try sut.skipStep(in: &session, caregiverID: "c1")) { error in
            if case GuidedActivityError.stepNotSkippable = error { return }
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Fatigue pacing

    func testFatiguePolicyBreakTriggeredAfterMaxBlock() async throws {
        let policy = FatiguePacingPolicy(restIntervalSeconds: 5, maxStepsPerBlock: 1, enforceAutoBreak: true)
        let prompt = makePrompt(body: "A. B. C.")
        var session = try await sut.begin(prompt: prompt, patientID: patientID, pacingPolicy: policy)
        try sut.completeStep(in: &session)
        XCTAssertEqual(session.state, .pausedForBreak)
    }

    func testFatigueBreakEventLogged() async throws {
        let policy = FatiguePacingPolicy(restIntervalSeconds: 5, maxStepsPerBlock: 1, enforceAutoBreak: true)
        let prompt = makePrompt(body: "A. B.")
        var session = try await sut.begin(prompt: prompt, patientID: patientID, pacingPolicy: policy)
        try sut.completeStep(in: &session)
        XCTAssertFalse(analytics.events(named: "activity.auto_break").isEmpty)
    }

    func testResumeResetsSessionToInProgress() async throws {
        let policy = FatiguePacingPolicy(restIntervalSeconds: 5, maxStepsPerBlock: 1, enforceAutoBreak: true)
        let prompt = makePrompt(body: "A. B.")
        var session = try await sut.begin(prompt: prompt, patientID: patientID, pacingPolicy: policy)
        try sut.completeStep(in: &session) // triggers break
        sut.resume(session: &session)
        XCTAssertEqual(session.state, .inProgress)
    }

    // MARK: - Abandon

    func testAbandonSetsAbandonedState() async throws {
        var session = try await sut.begin(prompt: makePrompt(), patientID: patientID)
        sut.abandon(session: &session)
        XCTAssertEqual(session.state, .abandoned)
    }

    func testAbandonLogsEvent() async throws {
        var session = try await sut.begin(prompt: makePrompt(), patientID: patientID)
        sut.abandon(session: &session)
        XCTAssertFalse(analytics.events(named: "activity.abandoned").isEmpty)
    }

    // MARK: - Completion / session summary

    func testFinaliseReturnsSummaryForCompletedSession() async throws {
        var session = try await sut.begin(prompt: makePrompt(body: "One."), patientID: patientID)
        try sut.completeStep(in: &session)
        let summary = try await sut.finalise(session: session)
        XCTAssertEqual(summary.completedSteps, 1)
    }

    func testFinaliseSchedulesCompletionNotification() async throws {
        var session = try await sut.begin(prompt: makePrompt(body: "One."), patientID: patientID)
        try sut.completeStep(in: &session)
        _ = try await sut.finalise(session: session)
        XCTAssertEqual(scheduler.activityCompletionCallCount, 1)
    }

    func testFinaliseOnNonTerminalSessionThrows() async throws {
        let session = try await sut.begin(prompt: makePrompt(), patientID: patientID)
        do {
            _ = try await sut.finalise(session: session)
            XCTFail("Expected error for non-terminal session")
        } catch {
            // expected
        }
    }

    // MARK: - Completion logging

    func testCompletedEventLoggedWhenLastStepDone() async throws {
        var session = try await sut.begin(prompt: makePrompt(body: "One."), patientID: patientID)
        try sut.completeStep(in: &session)
        XCTAssertFalse(analytics.events(named: "activity.completed").isEmpty)
    }

    // MARK: - Persistence failure

    func testBeginThrowsWhenRepositoryFails() async throws {
        repo.shouldFailOnSave = true
        let prompt = makePrompt()
        do {
            _ = try await sut.begin(prompt: prompt, patientID: patientID)
            XCTFail("Expected persistenceFailure error")
        } catch GuidedActivityError.persistenceFailure {
            // expected
        }
    }
}
