//
//  RecordingSession.swift
//  DementiaMedia – Domain Layer
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Tracks the lifecycle of a patient's audio or video recording attempt.
//  No AVFoundation import; state machine only.
//

import Foundation

/// Allowed media formats for recording.
public enum RecordingFormat: String, Codable, Sendable {
    case audioM4A = "m4a"
    case audioCAF = "caf"
    case videoMP4 = "mp4"
}

/// The lifecycle state of one recording attempt.
public enum RecordingState: String, Codable, Sendable, Equatable {
    case idle
    case recording
    case paused
    case stopped
    case failed
}

/// Domain errors specific to recording workflows.
public enum RecordingError: Error, Equatable {
    case permissionDenied
    case hardwareUnavailable
    case diskFull
    case maximumDurationExceeded(limit: TimeInterval)
    case interrupted(reason: String)
}

/// A value object capturing the outcome and metadata of one recording attempt.
public struct RecordingSession: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var patientID: UUID
    public var format: RecordingFormat
    public var state: RecordingState
    public var startedAt: Date?
    public var endedAt: Date?
    public var outputURL: URL?
    public var durationSeconds: Double?
    public var promptID: UUID?            // optional associated activity prompt

    /// Maximum allowed recording duration (5 minutes).
    public static let maximumDurationSeconds: Double = 300

    public init(
        id: UUID = .init(),
        patientID: UUID,
        format: RecordingFormat = .audioM4A,
        state: RecordingState = .idle,
        startedAt: Date? = nil,
        endedAt: Date? = nil,
        outputURL: URL? = nil,
        durationSeconds: Double? = nil,
        promptID: UUID? = nil
    ) {
        self.id = id
        self.patientID = patientID
        self.format = format
        self.state = state
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.outputURL = outputURL
        self.durationSeconds = durationSeconds
        self.promptID = promptID
    }

    /// Whether the current state is terminal (stopped or failed).
    public var isTerminal: Bool {
        state == .stopped || state == .failed
    }

    /// Whether a duration exceeds the policy limit.
    public func exceedsLimit(_ duration: TimeInterval) -> Bool {
        duration > RecordingSession.maximumDurationSeconds
    }
}
