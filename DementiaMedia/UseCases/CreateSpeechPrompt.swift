//
//  CreateSpeechPrompt.swift
//  DementiaMedia – Use Cases
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Outside-in TDD use case: converts a carer's ActivityPrompt into a
//  saved audio asset using the SpeechSynthesizing and MediaRepository ports.
//

import Foundation

/// Errors thrown by CreateSpeechPrompt.
public enum CreateSpeechPromptError: Error, Equatable {
    case emptyText
    case textTooLong(length: Int, limit: Int)
    case voiceUnavailable(identifier: String)
    case synthesisFailure(underlying: String)
    case persistenceFailure(underlying: String)
}

/// Converts an `ActivityPrompt` body into a saved `MediaAsset` audio file.
public final class CreateSpeechPrompt {

    private let synthesiser: SpeechSynthesizing
    private let repository: MediaRepository
    private let fileManager: FileManagerProtocol

    public init(
        synthesiser: SpeechSynthesizing,
        repository: MediaRepository,
        fileManager: FileManagerProtocol = DefaultFileManager()
    ) {
        self.synthesiser = synthesiser
        self.repository = repository
        self.fileManager = fileManager
    }

    /// Validates text, synthesises each chunk, then persists the resulting asset.
    /// Returns the saved `MediaAsset`.
    @discardableResult
    public func execute(
        prompt: ActivityPrompt,
        voice: SpeechVoiceOptions,
        ownerID: UUID
    ) async throws -> MediaAsset {

        // Validate text
        let text = prompt.bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw CreateSpeechPromptError.emptyText }
        guard text.count <= ActivityPrompt.maximumBodyTextLength else {
            throw CreateSpeechPromptError.textTooLong(
                length: text.count,
                limit: ActivityPrompt.maximumBodyTextLength
            )
        }

        // Validate voice availability
        let available = synthesiser.availableVoiceIdentifiers()
        guard available.contains(voice.identifier) else {
            throw CreateSpeechPromptError.voiceUnavailable(identifier: voice.identifier)
        }

        // Build output URL
        let filename = "speech_\(prompt.id.uuidString).m4a"
        let outputURL = fileManager.temporaryDirectory.appendingPathComponent(filename)

        do {
            try await synthesiser.synthesise(text: text, voice: voice, to: outputURL)
        } catch {
            throw CreateSpeechPromptError.synthesisFailure(underlying: error.localizedDescription)
        }

        // Build asset record
        var asset = MediaAsset(
            ownerID: ownerID,
            kind: .audioPrompt,
            title: prompt.title,
            localURL: outputURL,
            state: .saved,
            tags: prompt.tags
        )

        do {
            try await repository.save(asset)
        } catch {
            throw CreateSpeechPromptError.persistenceFailure(underlying: error.localizedDescription)
        }

        asset.state = .saved
        return asset
    }
}

// MARK: - FileManagerProtocol (abstraction for testability)

public protocol FileManagerProtocol {
    var temporaryDirectory: URL { get }
    func fileExists(atPath path: String) -> Bool
}

public final class DefaultFileManager: FileManagerProtocol {
    public init() {}
    public var temporaryDirectory: URL { FileManager.default.temporaryDirectory }
    public func fileExists(atPath path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }
}
