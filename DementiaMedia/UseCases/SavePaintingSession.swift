//
//  SavePaintingSession.swift
//  DementiaMedia – Use Cases
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Validates, persists, and names a patient's painting canvas export.
//

import Foundation

public enum SavePaintingError: Error, Equatable {
    case emptyCanvas           // Zero-byte PNG data
    case titleTooLong(limit: Int)
    case persistenceFailure(underlying: String)
}

/// Saves a PencilKit canvas export as a MediaAsset painting.
public final class SavePaintingSession {

    public static let maximumTitleLength = 80

    private let repository: MediaRepository
    private let fileManager: FileManagerProtocol

    public init(
        repository: MediaRepository,
        fileManager: FileManagerProtocol = DefaultFileManager()
    ) {
        self.repository = repository
        self.fileManager = fileManager
    }

    /// Writes `pngData` to the temporary directory, creates and persists a
    /// `MediaAsset` record, and returns it.
    @discardableResult
    public func execute(
        pngData: Data,
        title: String,
        ownerID: UUID,
        tags: [String] = []
    ) async throws -> MediaAsset {

        // Validate content
        guard !pngData.isEmpty else { throw SavePaintingError.emptyCanvas }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedTitle.count <= Self.maximumTitleLength else {
            throw SavePaintingError.titleTooLong(limit: Self.maximumTitleLength)
        }

        // Derive a auto-generated title if blank
        let resolvedTitle = trimmedTitle.isEmpty
            ? "Painting \(Self.dateStamp())"
            : trimmedTitle

        // Write file
        let filename = "painting_\(UUID().uuidString).png"
        let outputURL = fileManager.temporaryDirectory.appendingPathComponent(filename)
        try pngData.write(to: outputURL)

        // Build asset record
        let asset = MediaAsset(
            ownerID: ownerID,
            kind: .painting,
            title: resolvedTitle,
            localURL: outputURL,
            state: .saved,
            tags: tags
        )

        do {
            try await repository.save(asset)
        } catch {
            throw SavePaintingError.persistenceFailure(underlying: error.localizedDescription)
        }

        return asset
    }

    // MARK: - Private helpers

    private static func dateStamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy"
        return f.string(from: Date())
    }
}
