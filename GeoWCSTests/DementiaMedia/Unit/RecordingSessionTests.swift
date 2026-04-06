//
//  RecordingSessionTests.swift
//  GeoWCSTests – DementiaMedia Unit Tests
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Pure domain tests for RecordingSession state machine and policy rules.
//

import XCTest
@testable import DementiaMedia

final class RecordingSessionTests: XCTestCase {

    private func makeSession(
        state: RecordingState = .idle,
        duration: Double? = nil
    ) -> RecordingSession {
        RecordingSession(
            patientID: UUID(),
            format: .audioM4A,
            state: state,
            durationSeconds: duration
        )
    }

    // MARK: - Initial state

    func testNewSessionIsIdle() {
        let session = makeSession()
        XCTAssertEqual(session.state, .idle)
    }

    func testNewSessionHasNoOutputURL() {
        XCTAssertNil(makeSession().outputURL)
    }

    func testNewSessionHasNoDuration() {
        XCTAssertNil(makeSession().durationSeconds)
    }

    // MARK: - Terminal states

    func testStoppedSessionIsTerminal() {
        XCTAssertTrue(makeSession(state: .stopped).isTerminal)
    }

    func testFailedSessionIsTerminal() {
        XCTAssertTrue(makeSession(state: .failed).isTerminal)
    }

    func testRecordingSessionIsNotTerminal() {
        XCTAssertFalse(makeSession(state: .recording).isTerminal)
    }

    func testPausedSessionIsNotTerminal() {
        XCTAssertFalse(makeSession(state: .paused).isTerminal)
    }

    // MARK: - Duration policy

    func testDurationBelowLimitDoesNotExceed() {
        let session = makeSession(duration: 299)
        XCTAssertFalse(session.exceedsLimit(299))
    }

    func testDurationAtLimitDoesNotExceed() {
        let limit = RecordingSession.maximumDurationSeconds
        let session = makeSession(duration: limit)
        XCTAssertFalse(session.exceedsLimit(limit))
    }

    func testDurationOneSecondOverLimitExceeds() {
        let over = RecordingSession.maximumDurationSeconds + 1
        let session = makeSession(duration: over)
        XCTAssertTrue(session.exceedsLimit(over))
    }

    func testMaximumDurationPolicyIs5Minutes() {
        XCTAssertEqual(RecordingSession.maximumDurationSeconds, 300,
            "Policy must be exactly 5 minutes (300 s)")
    }

    // MARK: - Codable round-trip

    func testSessionSurvivesJSONRoundTrip() throws {
        let original = RecordingSession(
            patientID: UUID(),
            format: .videoMP4,
            state: .stopped,
            startedAt: Date(timeIntervalSince1970: 1700000000),
            endedAt: Date(timeIntervalSince1970: 1700000120),
            durationSeconds: 120
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RecordingSession.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - Identity

    func testTwoSessionsWithDifferentIDsAreNotEqual() {
        let s1 = makeSession()
        let s2 = makeSession()
        XCTAssertNotEqual(s1.id, s2.id)
        XCTAssertNotEqual(s1, s2)
    }
}
