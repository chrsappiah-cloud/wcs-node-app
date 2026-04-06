//
//  RecordMemoryClip.swift
//  DementiaMedia – Use Cases
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Orchestrates permission checking, session lifecycle management, and
//  persistence of a patient's memory recording.
//

import Foundation

public enum RecordMemoryClipError: Error, Equatable {
    case permissionDenied
    case alreadyRecording
    case notRecording
    case maximumDurationExceeded(limit: TimeInterval)
    case hardwareUnavailable
    case persistenceFailure(underlying: String)
}

/// Manages the full lifecycle of one memory-recording attempt.
public final class RecordMemoryClip {

    private let recorder: AudioRecording
    private let repository: MediaRepository
    private let fileManager: FileManagerProtocol

    public init(
        recorder: AudioRecording,
        repository: MediaRepository,
        fileManager: FileManagerProtocol = DefaultFileManager()
    ) {
        self.recorder = recorder
        self.repository = repository
        self.fileManager = fileManager
    }

    // MARK: - Start

    /// Requests microphone permission and begins recording.
    /// Throws if permission is denied or hardware is unavailable.
    public func start(for patientID: UUID, promptID: UUID? = nil) async throws {
        guard recorder.state == .idle || recorder.state == .stopped else {
            throw RecordMemoryClipError.alreadyRecording
        }
        let granted = await recorder.requestPermission()
        guard granted else { throw RecordMemoryClipError.permissionDenied }

        let filename = "memory_\(patientID.uuidString)_\(UUID().uuidString).m4a"
        let outputURL = fileManager.temporaryDirectory.appendingPathComponent(filename)
        do {
            try recorder.start(to: outputURL)
        } catch {
            throw RecordMemoryClipError.hardwareUnavailable
        }
    }

    // MARK: - Stop + Persist

    /// Stops the recording, validates the duration, and persists the asset.
    @discardableResult
    public func stop(ownerID: UUID, title: String) async throws -> MediaAsset {
        guard recorder.state == .recording || recorder.state == .paused else {
            throw RecordMemoryClipError.notRecording
        }

        let session: RecordingSession
        do {
            session = try await recorder.stop()
        } catch {
            throw RecordMemoryClipError.hardwareUnavailable
        }

        // Enforce duration policy
        if let duration = session.durationSeconds,
           session.exceedsLimit(duration) {
            throw RecordMemoryClipError.maximumDurationExceeded(
                limit: RecordingSession.maximumDurationSeconds
            )
        }

        let asset = MediaAsset(
            ownerID: ownerID,
            kind: .memoryRecording,
            title: title.isEmpty ? "Memory \(Self.timestamp())" : title,
            localURL: session.outputURL,
            durationSeconds: session.durationSeconds,
            state: .saved
        )

        do {
            try await repository.save(asset)
        } catch {
            throw RecordMemoryClipError.persistenceFailure(underlying: error.localizedDescription)
        }

        return asset
    }

    // MARK: - Private helpers

    private static func timestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM HH:mm"
        return f.string(from: Date())
    }
}
