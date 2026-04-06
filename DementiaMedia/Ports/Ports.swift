//
//  Ports.swift
//  DementiaMedia – Ports Layer
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Protocol definitions (ports) that isolate business logic from Apple
//  framework implementations. Each protocol has exactly one responsibility
//  so fakes can be written in a few lines and swapped per test.
//

import Foundation

// MARK: - SpeechSynthesizing

/// Converts text to an audio file at the given destination URL.
public protocol SpeechSynthesizing: AnyObject {
    /// Synthesises `text` and writes the audio to `outputURL`.
    /// Throws if the voice is unavailable or synthesis fails.
    func synthesise(
        text: String,
        voice: SpeechVoiceOptions,
        to outputURL: URL
    ) async throws

    /// Returns identifiers of locally available voices.
    func availableVoiceIdentifiers() -> [String]
}

/// Voice configuration passed to the synthesiser.
public struct SpeechVoiceOptions: Equatable, Sendable {
    public var identifier: String
    public var speedMultiplier: Double    // 0.25 – 2.0
    public var pitchMultiplier: Float     // 0.5 – 2.0

    public static let calm = SpeechVoiceOptions(
        identifier: "com.apple.voice.compact.en-GB.Daniel",
        speedMultiplier: 0.85,
        pitchMultiplier: 1.0
    )

    public init(identifier: String, speedMultiplier: Double, pitchMultiplier: Float) {
        self.identifier = identifier
        self.speedMultiplier = speedMultiplier
        self.pitchMultiplier = pitchMultiplier
    }
}

// MARK: - AudioRecording

/// Manages live audio capture from the device microphone.
public protocol AudioRecording: AnyObject {
    var state: RecordingState { get }

    func requestPermission() async -> Bool
    func start(to outputURL: URL) throws
    func pause()
    func resume() throws
    func stop() async throws -> RecordingSession
}

// MARK: - VideoRendering

/// Converts a sequence of images to a video file.
public protocol VideoRendering: AnyObject {
    /// Renders images at `imageURLs` to a video at `outputURL`.
    /// `frameRate` defaults to 1 fps for slide-show style content.
    func render(
        imageURLs: [URL],
        to outputURL: URL,
        frameRate: Double
    ) async throws
}

// MARK: - ImagePicking

/// Provides images from the device photo library or camera.
public protocol ImagePicking: AnyObject {
    /// Returns URLs pointing to items the user selected.
    /// An empty array means the user cancelled.
    func pickImages(limit: Int) async throws -> [URL]
}

// MARK: - MediaRepository

/// Persists and retrieves MediaAsset records and their associated files.
public protocol MediaRepository: AnyObject {
    func save(_ asset: MediaAsset) async throws
    func fetch(id: UUID) async throws -> MediaAsset?
    func fetchAll(ownerID: UUID) async throws -> [MediaAsset]
    func delete(id: UUID) async throws
    func update(_ asset: MediaAsset) async throws
}

// MARK: - PaintingExporting

/// Serialises a PencilKit canvas to image data.
public protocol PaintingExporting: AnyObject {
    /// Returns PNG data for the current canvas state.
    func exportPNG() throws -> Data
}

// MARK: - NotificationScheduling

/// Schedules and cancels local user notifications.
public protocol NotificationScheduling: AnyObject {
    func schedule(
        identifier: String,
        title: String,
        body: String,
        triggerDate: Date
    ) async throws
    func cancel(identifier: String)
    /// Convenience: schedules a gentle "well done" notification after an activity.
    func scheduleActivityCompletion(
        patientID: UUID,
        title: String,
        completedAt: Date
    ) async throws
}
