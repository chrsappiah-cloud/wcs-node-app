//
//  RecordMemoryClipTests.swift
//  GeoWCSTests – DementiaMedia Unit Tests
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Unit tests for RecordMemoryClip use case.
//  Covers: permissions, lifecycle enforcement, duration policy, persistence.
//

import XCTest
@testable import DementiaMedia

final class RecordMemoryClipTests: XCTestCase {

    private var recorder: FakeAudioRecorder!
    private var repository: FakeMediaRepository!
    private var fileManager: FakeFileManager!
    private var sut: RecordMemoryClip!

    private let patientID = UUID()

    override func setUp() {
        super.setUp()
        recorder    = FakeAudioRecorder()
        repository  = FakeMediaRepository()
        fileManager = FakeFileManager()
        sut = RecordMemoryClip(recorder: recorder,
                               repository: repository,
                               fileManager: fileManager)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Permission

    func testStartRequestsPermission() async throws {
        try await sut.start(for: patientID)
        XCTAssertEqual(recorder.requestPermissionCallCount, 1)
    }

    func testStartGrantedBeginsMicrophone() async throws {
        recorder.permissionGranted = true
        try await sut.start(for: patientID)
        XCTAssertEqual(recorder.startCallCount, 1)
    }

    func testDeniedPermissionThrowsCorrectError() async {
        recorder.permissionGranted = false
        do {
            try await sut.start(for: patientID)
            XCTFail("Expected permissionDenied error")
        } catch let err as RecordMemoryClipError {
            XCTAssertEqual(err, .permissionDenied)
        }
    }

    func testDeniedPermissionDoesNotStartRecorder() async {
        recorder.permissionGranted = false
        _ = try? await sut.start(for: patientID)
        XCTAssertEqual(recorder.startCallCount, 0)
    }

    // MARK: - Already recording guard

    func testStartingWhenAlreadyRecordingThrows() async throws {
        try await sut.start(for: patientID)  // first start
        do {
            try await sut.start(for: patientID)  // second start
            XCTFail("Expected alreadyRecording error")
        } catch let err as RecordMemoryClipError {
            XCTAssertEqual(err, .alreadyRecording)
        }
    }

    // MARK: - Hardware failure

    func testHardwareFailureOnStartThrowsCorrectError() async {
        recorder.shouldFailOnStart = true
        do {
            try await sut.start(for: patientID)
            XCTFail("Expected hardwareUnavailable error")
        } catch let err as RecordMemoryClipError {
            XCTAssertEqual(err, .hardwareUnavailable)
        }
    }

    // MARK: - Stop + persist

    func testStopPersistsRecordingAsMemoryClip() async throws {
        try await sut.start(for: patientID)
        let asset = try await sut.stop(ownerID: patientID, title: "Grandma's voice")
        XCTAssertEqual(asset.kind, .memoryRecording)
        XCTAssertEqual(asset.ownerID, patientID)
        XCTAssertEqual(asset.state, .saved)
        XCTAssertEqual(repository.saveCallCount, 1)
    }

    func testStopUsesProvidedTitle() async throws {
        try await sut.start(for: patientID)
        let asset = try await sut.stop(ownerID: patientID, title: "Park visit")
        XCTAssertEqual(asset.title, "Park visit")
    }

    func testStopWithBlankTitleGetsAutoTitle() async throws {
        try await sut.start(for: patientID)
        let asset = try await sut.stop(ownerID: patientID, title: "")
        XCTAssertFalse(asset.title.isEmpty)
        XCTAssertTrue(asset.title.hasPrefix("Memory "))
    }

    func testStopWhenNotRecordingThrows() async {
        do {
            _ = try await sut.stop(ownerID: patientID, title: "Bad")
            XCTFail("Expected notRecording error")
        } catch let err as RecordMemoryClipError {
            XCTAssertEqual(err, .notRecording)
        }
    }

    // MARK: - Duration policy

    func testRecordingExceedingMaximumDurationThrows() async throws {
        recorder.stubDurationSeconds = RecordingSession.maximumDurationSeconds + 1
        try await sut.start(for: patientID)
        do {
            _ = try await sut.stop(ownerID: patientID, title: "Too long")
            XCTFail("Expected maximumDurationExceeded error")
        } catch let err as RecordMemoryClipError {
            if case .maximumDurationExceeded(let limit) = err {
                XCTAssertEqual(limit, RecordingSession.maximumDurationSeconds)
            } else {
                XCTFail("Wrong error: \(err)")
            }
        }
    }

    func testRecordingAtExactMaximumDurationSucceeds() async throws {
        recorder.stubDurationSeconds = RecordingSession.maximumDurationSeconds
        try await sut.start(for: patientID)
        let asset = try await sut.stop(ownerID: patientID, title: "Exactly 5 min")
        XCTAssertEqual(asset.durationSeconds, RecordingSession.maximumDurationSeconds)
    }

    // MARK: - Repository failure

    func testRepositoryFailureThrowsPersistenceError() async throws {
        repository.shouldFailOnSave = true
        try await sut.start(for: patientID)
        do {
            _ = try await sut.stop(ownerID: patientID, title: "Fail")
            XCTFail("Expected persistenceFailure error")
        } catch let err as RecordMemoryClipError {
            if case .persistenceFailure = err { /* expected */ } else {
                XCTFail("Wrong error: \(err)")
            }
        }
    }
}
