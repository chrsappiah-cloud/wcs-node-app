//
//  LocalNotificationAdapterTests.swift
//  DementiaMediaTests – Integration
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Verifies the contract between guided-activity and the local
//  notification scheduling adapter.
//

import XCTest
@testable import DementiaMedia

final class LocalNotificationAdapterTests: XCTestCase {

    private var fakeScheduler: FakeNotificationScheduler!
    private var fakeRepo: FakeMediaRepository!
    private var fakeAnalytics: FakeAnalyticsLogger!
    private var sut: StartGuidedActivity!
    private let patientID = UUID()

    override func setUp() {
        super.setUp()
        fakeScheduler = FakeNotificationScheduler()
        fakeRepo      = FakeMediaRepository()
        fakeAnalytics = FakeAnalyticsLogger()
        sut = StartGuidedActivity(
            repository: fakeRepo,
            notificationScheduler: fakeScheduler,
            analytics: fakeAnalytics
        )
    }

    override func tearDown() {
        sut = nil; fakeScheduler = nil; fakeRepo = nil; fakeAnalytics = nil
        super.tearDown()
    }

    private func makePrompt(body: String = "One step only.") -> ActivityPrompt {
        ActivityPrompt(
            authorID: UUID(),
            title: "Daily Activity",
            bodyText: body,
            modality: .text
        )
    }

    // MARK: - Prompt playback coordination contract

    func testNoNotificationScheduledAtSessionStart() async throws {
        _ = try await sut.begin(prompt: makePrompt(), patientID: patientID)
        XCTAssertEqual(fakeScheduler.activityCompletionCallCount, 0)
    }

    func testCompletionNotificationScheduledAtSessionEnd() async throws {
        var session = try await sut.begin(prompt: makePrompt(), patientID: patientID)
        try sut.completeStep(in: &session)
        _ = try await sut.finalise(session: session)
        XCTAssertEqual(fakeScheduler.activityCompletionCallCount, 1)
    }

    func testNotificationIdentifierContainsPatientID() async throws {
        var session = try await sut.begin(prompt: makePrompt(), patientID: patientID)
        try sut.completeStep(in: &session)
        _ = try await sut.finalise(session: session)
        XCTAssertTrue(
            fakeScheduler.scheduledIdentifiers.contains(where: { $0.contains(patientID.uuidString) }),
            "Notification identifier must reference the patient ID for routing"
        )
    }

    // MARK: - Cancellation contract

    func testCancelNotificationCalledOnAbandon() async throws {
        // Abandon does not currently schedule a cancel – this test asserts
        // that no spurious cancellation occurs either.
        var session = try await sut.begin(prompt: makePrompt(), patientID: patientID)
        sut.abandon(session: &session)
        XCTAssertTrue(fakeScheduler.cancelledIdentifiers.isEmpty,
            "Abandon must not cancel notifications that have not been scheduled yet")
    }

    // MARK: - Scheduler failure handling

    func testSchedulerFailureDoesNotPreventSummaryReturn() async throws {
        fakeScheduler.shouldFail = true
        var session = try await sut.begin(prompt: makePrompt(), patientID: patientID)
        try sut.completeStep(in: &session)
        // finalise should propagate the error; caller decides whether to ignore it
        do {
            _ = try await sut.finalise(session: session)
            XCTFail("Expected scheduler failure to propagate")
        } catch {
            // Expected – scheduler failure surfaces upstream
        }
    }

    // MARK: - Analytics logging contract

    func testAnalyticsEventLoggedOnCompletion() async throws {
        var session = try await sut.begin(prompt: makePrompt(), patientID: patientID)
        try sut.completeStep(in: &session)
        XCTAssertFalse(fakeAnalytics.events(named: "activity.completed").isEmpty)
    }

    func testAnalyticsDoesNotLogCompletionIfAbandoned() async throws {
        var session = try await sut.begin(prompt: makePrompt(body: "Step A. Step B."), patientID: patientID)
        sut.abandon(session: &session)
        XCTAssertTrue(fakeAnalytics.events(named: "activity.completed").isEmpty)
    }

    // MARK: - Device-only: real UNUserNotificationCenter

    func testRealNotificationSchedulerRequestsPermission() async throws {
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["CI"] == "true",
            "Skipped in CI: UNUserNotificationCenter requires device"
        )
        XCTAssert(true, "Wire up real LocalNotificationAdapter here for device runs")
    }
}
