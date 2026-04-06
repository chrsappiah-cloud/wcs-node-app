//
//  FakeAdapters.swift
//  DementiaMediaTests – Test Support
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  In-memory / controllable implementations of every port protocol.
//  These are the only dependencies injected in unit and integration tests.
//  They record calls so tests can make precise spy assertions.
//

import Foundation
@testable import DementiaMedia   // or the host module name as appropriate

// MARK: - FakeSpeechSynthesiser

final class FakeSpeechSynthesiser: SpeechSynthesizing {

    // --- Configuration ---
    var availableVoices: [String] = ["com.apple.voice.compact.en-GB.Daniel",
                                      "com.apple.voice.compact.en-US.Samantha"]
    /// Set to `true` to simulate synthesis failure.
    var shouldFail = false
    var failureMessage = "Fake synthesis error"

    // --- Spies ---
    private let callSpy = CallSpy()
    var synthesisCallCount: Int { callSpy.callCount(for: "synthesise") }
    private(set) var lastSynthesisText: String?
    private(set) var lastVoiceOptions: SpeechVoiceOptions?
    private(set) var lastOutputURL: URL?

    func wasSynthesiseCalled() -> Bool {
        callSpy.wasCalled("synthesise")
    }

    func synthesise(text: String, voice: SpeechVoiceOptions, to outputURL: URL) async throws {
        callSpy.record("synthesise")
        lastSynthesisText = text
        lastVoiceOptions = voice
        lastOutputURL = outputURL
        if shouldFail { throw NSError(domain: "FakeSpeech", code: -1,
                                       userInfo: [NSLocalizedDescriptionKey: failureMessage]) }
        // Write a tiny placeholder so fileExists checks pass
        try Data("audio".utf8).write(to: outputURL)
    }

    func availableVoiceIdentifiers() -> [String] { availableVoices }
}

// MARK: - FakeAudioRecorder

final class FakeAudioRecorder: AudioRecording {

    // --- Configuration ---
    var permissionGranted = true
    var shouldFailOnStart = false
    var shouldFailOnStop = false
    var stubDurationSeconds: Double = 30.0
    var stubOutputURL: URL = FileManager.default.temporaryDirectory
        .appendingPathComponent("fake_recording.m4a")

    // --- Spies ---
    private(set) var requestPermissionCallCount = 0
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var pauseCallCount = 0

    // --- State ---
    private(set) var state: RecordingState = .idle
    private var _startedAt: Date?

    func requestPermission() async -> Bool {
        requestPermissionCallCount += 1
        return permissionGranted
    }

    func start(to outputURL: URL) throws {
        startCallCount += 1
        if shouldFailOnStart { throw NSError(domain: "FakeRecorder", code: -1) }
        state = .recording
        _startedAt = Date()
    }

    func pause() {
        pauseCallCount += 1
        state = .paused
    }

    func resume() throws { state = .recording }

    func stop() async throws -> RecordingSession {
        stopCallCount += 1
        if shouldFailOnStop { throw NSError(domain: "FakeRecorder", code: -2) }
        state = .stopped
        return RecordingSession(
            patientID: UUID(),
            format: .audioM4A,
            state: .stopped,
            startedAt: _startedAt,
            endedAt: Date(),
            outputURL: stubOutputURL,
            durationSeconds: stubDurationSeconds
        )
    }

    func reset() { state = .idle; _startedAt = nil }
}

// MARK: - FakeVideoRenderer

final class FakeVideoRenderer: VideoRendering {

    var shouldFail = false
    var shouldFailWithCancellation = false
    private(set) var renderCallCount = 0
    private(set) var lastImageURLs: [URL] = []
    private(set) var lastFrameRate: Double = 0

    func render(imageURLs: [URL], to outputURL: URL, frameRate: Double) async throws {
        renderCallCount += 1
        lastImageURLs = imageURLs
        lastFrameRate = frameRate
        if shouldFailWithCancellation { throw CancellationError() }
        if shouldFail { throw NSError(domain: "FakeRenderer", code: -1) }
        try Data("video".utf8).write(to: outputURL)
    }
}

// MARK: - FakeMediaRepository

final class FakeMediaRepository: MediaRepository {

    // Exposed as `store` so integration tests can simulate a relaunch by sharing state.
    private(set) var store: [UUID: MediaAsset]
    private var savedAssets: [UUID: MediaAsset] {
        get { store }
        set { store = newValue }
    }
    var shouldFailOnSave = false
    var shouldFailOnFetch = false

    private(set) var saveCallCount = 0
    private(set) var fetchAllCallCount = 0
    private(set) var deleteCallCount = 0

    init(existingStore: [UUID: MediaAsset] = [:]) {
        self.store = existingStore
    }

    func save(_ asset: MediaAsset) async throws {
        saveCallCount += 1
        if shouldFailOnSave { throw NSError(domain: "FakeRepo", code: -1) }
        savedAssets[asset.id] = asset
    }

    func fetch(id: UUID) async throws -> MediaAsset? {
        if shouldFailOnFetch { throw NSError(domain: "FakeRepo", code: -2) }
        return savedAssets[id]
    }

    func fetchAll(ownerID: UUID) async throws -> [MediaAsset] {
        fetchAllCallCount += 1
        return savedAssets.values.filter { $0.ownerID == ownerID }
    }

    func delete(id: UUID) async throws {
        deleteCallCount += 1
        savedAssets.removeValue(forKey: id)
    }

    func update(_ asset: MediaAsset) async throws {
        savedAssets[asset.id] = asset
    }
}

// MARK: - FakeFileManager

final class FakeFileManager: FileManagerProtocol {
    var temporaryDirectory: URL = URL(fileURLWithPath: NSTemporaryDirectory())
    var existingPaths: Set<String> = []

    func fileExists(atPath path: String) -> Bool { existingPaths.contains(path) }

    /// Helper to register a URL as existing.
    func register(_ url: URL) { existingPaths.insert(url.path) }
}

// MARK: - FakeNotificationScheduler

final class FakeNotificationScheduler: NotificationScheduling {

    private(set) var scheduledIdentifiers: [String] = []
    private(set) var cancelledIdentifiers: [String] = []
    private(set) var activityCompletionCallCount = 0
    var shouldFail = false

    func schedule(identifier: String, title: String, body: String, triggerDate: Date) async throws {
        if shouldFail { throw NSError(domain: "FakeNotif", code: -1) }
        scheduledIdentifiers.append(identifier)
    }

    func cancel(identifier: String) {
        cancelledIdentifiers.append(identifier)
    }

    func scheduleActivityCompletion(patientID: UUID, title: String, completedAt: Date) async throws {
        activityCompletionCallCount += 1
        if shouldFail { throw NSError(domain: "FakeNotif", code: -2) }
        scheduledIdentifiers.append("activity.\(patientID.uuidString)")
    }
}

// MARK: - FakeAnalyticsLogger

final class FakeAnalyticsLogger: ActivityAnalyticsLogging {

    struct LogEntry: Equatable {
        let event: String
        let sessionID: UUID
        let metadata: [String: String]
    }

    private(set) var entries: [LogEntry] = []

    func log(event: String, sessionID: UUID, metadata: [String: String]) {
        entries.append(LogEntry(event: event, sessionID: sessionID, metadata: metadata))
    }

    func events(named name: String) -> [LogEntry] {
        entries.filter { $0.event == name }
    }
}
