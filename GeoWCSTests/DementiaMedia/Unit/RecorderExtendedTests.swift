//
//  RecorderExtendedTests.swift
//  DementiaMediaTests – Unit
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Extended unit tests for RecordMemoryClip covering draft-discard rules,
//  metadata tagging, pause/resume transitions, transcript availability,
//  and interruption recovery beyond the baseline RecordMemoryClipTests.
//

import XCTest
@testable import DementiaMedia

final class RecorderExtendedTests: XCTestCase {

    // MARK: - Helpers

    private var fakeRecorder: FakeAudioRecorder!
    private var fakeRepo: FakeMediaRepository!
    private var sut: RecordMemoryClip!
    private let patientID = UUID()

    override func setUp() {
        super.setUp()
        fakeRecorder = FakeAudioRecorder()
        fakeRepo     = FakeMediaRepository()
        sut = RecordMemoryClip(recorder: fakeRecorder, repository: fakeRepo)
    }

    override func tearDown() {
        sut = nil
        fakeRecorder = nil
        fakeRepo = nil
        super.tearDown()
    }

    // MARK: - Draft discard rules

    func testDiscardingDraftDoesNotPersistAsset() async throws {
        fakeRecorder.permissionGranted = true
        try await sut.start(patientID: patientID, title: "Memory")
        // Abort without stopping
        fakeRecorder.simulateInterruption()
        XCTAssertEqual(fakeRepo.saveCallCount, 0,
            "An interrupted / never-stopped recording should not be persisted")
    }

    func testDraftIsNotVisibleInFetchAllAfterDiscard() async throws {
        fakeRecorder.permissionGranted = true
        try await sut.start(patientID: patientID, title: "Discarded clip")
        fakeRecorder.simulateInterruption()
        let all = try await fakeRepo.fetchAll(ownerID: patientID)
        XCTAssertTrue(all.isEmpty)
    }

    // MARK: - Metadata tagging

    func testSavedAssetCarriesProvidedTags() async throws {
        fakeRecorder.permissionGranted = true
        try await sut.start(patientID: patientID, title: "Seaside")
        fakeRecorder.stubDurationSeconds = 20
        let asset = try await sut.stop(tags: ["beach", "summer"])
        XCTAssertEqual(asset.tags, ["beach", "summer"])
    }

    func testSavedAssetHasCorrectKind() async throws {
        fakeRecorder.permissionGranted = true
        try await sut.start(patientID: patientID, title: "Morning")
        fakeRecorder.stubDurationSeconds = 10
        let asset = try await sut.stop(tags: [])
        XCTAssertEqual(asset.kind, .memoryRecording)
    }

    func testSavedAssetOwnerMatchesPatient() async throws {
        fakeRecorder.permissionGranted = true
        try await sut.start(patientID: patientID, title: "Grandchild visit")
        fakeRecorder.stubDurationSeconds = 15
        let asset = try await sut.stop(tags: [])
        XCTAssertEqual(asset.ownerID, patientID)
    }

    func testSavedAssetDurationMatchesRecording() async throws {
        fakeRecorder.permissionGranted = true
        try await sut.start(patientID: patientID, title: "Duration test")
        fakeRecorder.stubDurationSeconds = 45.5
        let asset = try await sut.stop(tags: [])
        XCTAssertEqual(asset.durationSeconds, 45.5, accuracy: 0.01)
    }

    // MARK: - Pause / resume transitions

    func testPauseTransitionsRecorderToPaused() async throws {
        fakeRecorder.permissionGranted = true
        try await sut.start(patientID: patientID, title: "Pause test")
        sut.pause()
        XCTAssertEqual(fakeRecorder.state, .paused)
    }

    func testResumeTransitionsRecorderToRecording() async throws {
        fakeRecorder.permissionGranted = true
        try await sut.start(patientID: patientID, title: "Resume test")
        sut.pause()
        try sut.resume()
        XCTAssertEqual(fakeRecorder.state, .recording)
    }

    func testMultiplePauseResumeCyclesTrackedCorrectly() async throws {
        fakeRecorder.permissionGranted = true
        try await sut.start(patientID: patientID, title: "Multi-pause")
        sut.pause()
        try sut.resume()
        sut.pause()
        try sut.resume()
        XCTAssertEqual(fakeRecorder.state, .recording)
    }

    func testResumeWithoutPauseDoesNotThrow() async throws {
        fakeRecorder.permissionGranted = true
        try await sut.start(patientID: patientID, title: "Resume without pause")
        // Resuming when not paused should be a no-op, not a crash
        XCTAssertNoThrow(try sut.resume())
    }

    // MARK: - Transcript availability

    func testTranscriptFlagDefaultsFalse() async throws {
        fakeRecorder.permissionGranted = true
        try await sut.start(patientID: patientID, title: "No transcript")
        fakeRecorder.stubDurationSeconds = 30
        let asset = try await sut.stop(tags: [])
        // Transcript generation is async and optional – flag should start false
        XCTAssertFalse(asset.tags.contains("transcript:ready"),
            "Transcript flag should not be set synchronously at save time")
    }

    // MARK: - Interruption recovery

    func testRestartAfterInterruptionSucceeds() async throws {
        fakeRecorder.permissionGranted = true
        try await sut.start(patientID: patientID, title: "First attempt")
        fakeRecorder.simulateInterruption()
        fakeRecorder.reset()

        // User restarts
        try await sut.start(patientID: patientID, title: "Second attempt")
        fakeRecorder.stubDurationSeconds = 20
        let asset = try await sut.stop(tags: [])
        XCTAssertEqual(asset.title, "Second attempt")
    }

    func testHardwareUnavailableAfterInterruptionThrows() async throws {
        fakeRecorder.permissionGranted = true
        try await sut.start(patientID: patientID, title: "Interrupted")
        fakeRecorder.simulateInterruption()
        fakeRecorder.shouldFailOnStart = true

        do {
            try await sut.start(patientID: patientID, title: "Retry")
            XCTFail("Expected error not thrown")
        } catch RecordingError.hardwareUnavailable {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - FakeAudioRecorder interruption helpers

private extension FakeAudioRecorder {
    /// Simulates an external interruption (phone call, Siri, etc.)
    func simulateInterruption() {
        // Drive the state machine to failed/idle without going through `stop`
        if state == .recording || state == .paused {
            // Directly force state to idle to simulate discard
            reset()
        }
    }
}
