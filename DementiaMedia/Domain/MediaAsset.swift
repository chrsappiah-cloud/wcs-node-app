//
//  MediaAsset.swift
//  DementiaMedia – Domain Layer
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Represents any persisted media item produced by the app.
//  Pure value type; no dependency on Photos, AVFoundation, or UIKit.
//

import Foundation

/// The kind of content stored by a MediaAsset.
public enum MediaKind: String, Codable, Sendable {
    case painting        // PencilKit canvas snapshot (PNG/JPEG)
    case audioPrompt     // Text-to-speech output (.m4a)
    case memoryRecording // Patient-recorded audio (.m4a / .caf)
    case videoMemory     // Patient-recorded video (.mp4)
    case slideshow       // Exported image-sequence video (.mp4)
    case importedPhoto   // Picked from Photos library
    case activitySession // Guided-activity session record
}

/// Lifecycle state of an asset.
public enum AssetState: String, Codable, Sendable {
    case draft       // In-progress, not saved to repository
    case saved       // Persisted locally
    case exported    // Shared or written to Photos
    case archived    // Hidden from main library; recoverable
}

/// A single media item owned by one patient.
public struct MediaAsset: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var ownerID: UUID
    public var kind: MediaKind
    public var title: String
    public var localURL: URL?
    public var durationSeconds: Double?    // nil for static images
    public var thumbnailURL: URL?
    public var createdAt: Date
    public var state: AssetState
    /// Tags for activity categorisation (e.g. "morning", "music", "ocean").
    public var tags: [String]

    public init(
        id: UUID = .init(),
        ownerID: UUID,
        kind: MediaKind,
        title: String,
        localURL: URL? = nil,
        durationSeconds: Double? = nil,
        thumbnailURL: URL? = nil,
        createdAt: Date = Date(),
        state: AssetState = .draft,
        tags: [String] = []
    ) {
        self.id = id
        self.ownerID = ownerID
        self.kind = kind
        self.title = title
        self.localURL = localURL
        self.durationSeconds = durationSeconds
        self.thumbnailURL = thumbnailURL
        self.createdAt = createdAt
        self.state = state
        self.tags = tags
    }
}
