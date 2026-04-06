//
//  AudioRecordingIntegrationTests.swift
//  GeoWCSTests – DementiaMedia Integration Tests
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Boundary tests for the audio recording pipeline.
//  Uses FakeAudioRecorder so no microphone hardware is required in CI.
//  Documents the real AVFoundation adapter contract for device testing.
//

import XCTest
@testable import DementiaMedia

final class AudioRecordingIntegrationTests: XCTestCase {

    private var recorder: FakeAudioRecorder!
    private var repository: FakeMediaRepository!
    private var sut: RecordMemoryClip!

    private let patientID = UUID()

    override func setUp() {
        super.setUp()
        recorder   = FakeAudioRecorder()
        repository = FakeMediaRepository()
        sut = RecordMemoryClip(recorder: recorder, repository: repository)
    }

    // MARK: - Full lifecycle

    func testFullRecordLifecycleSavesAssetWithDuration() async throws {
        recorder.stubDurationSeconds = 45
        try await sut.start(for: patientID)
        let asset = try await sut.stop(ownerID: patientID, title: "Morning birds")

        XCTAssertEqual(asset.durationSeconds, 45)
        XCTAssertNotNil(asset.localURL)
        XCTAssertEqual(asset.kind, .memoryRecording)
    }

    func testMultipleSessionsAreIndependent() async throws {
        // Session 1
        recorder.stubDurationSeconds = 30
        try await sut.start(for: patientID)
        let a1 = try await sut.stop(ownerID: patientID, title: "Session 1")

        // Reset recorder state to allow second start
        recorder.reset()

        // Session 2
        recorder.stubDurationSeconds = 60
        try await sut.start(for: patientID)
        let a2 = try await sut.stop(ownerID: patientID, title: "Session 2")

        XCTAssertNotEqual(a1.id, a2.id)
        XCTAssertEqual(a1.durationSeconds, 30)
        XCTAssertEqual(a2.durationSeconds, 60)
        XCTAssertEqual(repository.saveCallCount, 2)
    }

    // MARK: - Pause / resume simulation

    func testPauseAndResumeDoesNotBreakLifecycle() async throws {
        try await sut.start(for: patientID)
        recorder.pause()
        XCTAssertEqual(recorder.state, .paused)
        try recorder.resume()
        XCTAssertEqual(recorder.state, .recording)
        let asset = try await sut.stop(ownerID: patientID, title: "Paused session")
        XCTAssertEqual(asset.state, .saved)
    }

    // MARK: - File output

    func testOutputURLIsSetOnSavedAsset() async throws {
        try await sut.start(for: patientID)
        let asset = try await sut.stop(ownerID: patientID, title: "URL check")

        guard let url = asset.localURL else {
            XCTFail("localURL must be set on saved memory clip")
            return
        }
        XCTAssertTrue(url.pathExtension == "m4a" || url.pathExtension == "caf",
            "Output must be an audio file")
    }

    // MARK: - Repository round-trip

    func testSavedAssetCanBeRetrievedFromRepository() async throws {
        try await sut.start(for: patientID)
        let saved = try await sut.stop(ownerID: patientID, title: "Replay test")

        let fetched = try await repository.fetch(id: saved.id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.title, "Replay test")
    }

    func testFetchAllReturnsOnlyCurrentPatientsAssets() async throws {
        let otherID = UUID()

        recorder.reset()
        try await sut.start(for: patientID)
        _ = try await sut.stop(ownerID: patientID, title: "Mine")

        recorder.reset()
        let otherSut = RecordMemoryClip(recorder: recorder, repository: repository)
        try await otherSut.start(for: otherID)
        _ = try await otherSut.stop(ownerID: otherID, title: "Theirs")

        let ours = try await repository.fetchAll(ownerID: patientID)
        XCTAssertEqual(ours.count, 1)
        XCTAssertEqual(ours.first?.ownerID, patientID)
    }

    // MARK: - Real AVFoundation adapter contract documentation

    func testRealAdapterRequiresMicrophonePermissionBeforeStart() throws {
        try XCTSkipIf(ProcessInfo.processInfo.environment["CI"] == "true",
                      "Skipped in CI — requires microphone entitlement")
        // Documentation:
        // 1. requestPermission() must show system prompt on first call
        // 2. start() must throw hardwareUnavailable if permission denied
        // 3. stop() must produce a valid .m4a at the given URL
        // 4. stop() must record elapsed wall-clock duration accurately (±1 s)
    }
}
