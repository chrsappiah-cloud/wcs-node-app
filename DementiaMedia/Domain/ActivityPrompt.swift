//
//  ActivityPrompt.swift
//  DementiaMedia – Domain Layer
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  A carer-authored guided-activity instruction that the app
//  can render as text, read aloud, or present as an image cue.
//

import Foundation

/// The sensory channel through which a prompt is primarily delivered.
public enum PromptModality: String, Codable, Sendable {
    case text, audio, visual, combined
}

/// Difficulty level for cognitive load management.
public enum PromptDifficulty: Int, Codable, Sendable, Comparable {
    case veryEasy = 0, easy = 1, moderate = 2

    public static func < (lhs: PromptDifficulty, rhs: PromptDifficulty) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// A single guided-activity instruction record.
public struct ActivityPrompt: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var bodyText: String
    public var modality: PromptModality
    public var difficulty: PromptDifficulty
    public var durationHint: TimeInterval?   // suggested engagement time in seconds
    public var imageAssetID: UUID?           // optional companion image
    public var audioAssetID: UUID?           // pre-rendered TTS or recorded voice
    public var tags: [String]
    public var authoredByCarerID: UUID

    public init(
        id: UUID = .init(),
        title: String,
        bodyText: String,
        modality: PromptModality = .text,
        difficulty: PromptDifficulty = .easy,
        durationHint: TimeInterval? = nil,
        imageAssetID: UUID? = nil,
        audioAssetID: UUID? = nil,
        tags: [String] = [],
        authoredByCarerID: UUID
    ) {
        self.id = id
        self.title = title
        self.bodyText = bodyText
        self.modality = modality
        self.difficulty = difficulty
        self.durationHint = durationHint
        self.imageAssetID = imageAssetID
        self.audioAssetID = audioAssetID
        self.tags = tags
        self.authoredByCarerID = authoredByCarerID
    }

    // MARK: - Validation

    /// Maximum allowed plain-text length for TTS chunking.
    public static let maximumBodyTextLength = 500

    /// Returns `true` if text can be synthesised without chunking.
    public var requiresChunking: Bool {
        bodyText.count > ActivityPrompt.maximumBodyTextLength
    }

    /// Chunks body text into synthesisable segments ≤ maximumBodyTextLength.
    public func textChunks() -> [String] {
        guard requiresChunking else { return [bodyText] }
        var chunks: [String] = []
        var remaining = bodyText
        while !remaining.isEmpty {
            let end = remaining.index(remaining.startIndex,
                                      offsetBy: ActivityPrompt.maximumBodyTextLength,
                                      limitedBy: remaining.endIndex) ?? remaining.endIndex
            // Break at sentence boundary if possible
            let candidate = String(remaining[..<end])
            if let lastPeriod = candidate.range(of: ".", options: .backwards) {
                let chunk = String(candidate[...lastPeriod.lowerBound])
                chunks.append(chunk.trimmingCharacters(in: .whitespaces))
                remaining = String(remaining[lastPeriod.upperBound...])
                    .trimmingCharacters(in: .whitespaces)
            } else {
                chunks.append(candidate.trimmingCharacters(in: .whitespaces))
                remaining = String(remaining[end...])
                    .trimmingCharacters(in: .whitespaces)
            }
        }
        return chunks.filter { !$0.isEmpty }
    }
}
