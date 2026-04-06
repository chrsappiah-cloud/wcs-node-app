//
//  ExportSlideshow.swift
//  DementiaMedia – Use Cases
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Composes a video slideshow from a patient's saved images or paintings.
//

import Foundation

public enum ExportSlideshowError: Error, Equatable {
    case noImages
    case tooManyImages(limit: Int)
    case invalidFrameRate
    case storageFull
    case imageMissing(url: String)
    case renderFailure(underlying: String)
    case persistenceFailure(underlying: String)
}

/// Builds a video slideshow from an ordered list of image MediaAssets.
public final class ExportSlideshow {

    public static let maximumImageCount = 50
    public static let validFrameRateRange: ClosedRange<Double> = 0.25...5.0
    public static let defaultFrameRate: Double = 1.0     // 1 image per second

    private let renderer: VideoRendering
    private let repository: MediaRepository
    private let fileManager: FileManagerProtocol
    private let storagePolicy: StorageThresholdPolicy
    private let freeStorageBytesProvider: () -> Int64

    public init(
        renderer: VideoRendering,
        repository: MediaRepository,
        fileManager: FileManagerProtocol = DefaultFileManager(),
        storagePolicy: StorageThresholdPolicy = .default,
        freeStorageBytesProvider: @escaping () -> Int64 = {
            let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSTemporaryDirectory())
            return (attrs?[.systemFreeSize] as? NSNumber)?.int64Value ?? Int64.max
        }
    ) {
        self.renderer = renderer
        self.repository = repository
        self.fileManager = fileManager
        self.storagePolicy = storagePolicy
        self.freeStorageBytesProvider = freeStorageBytesProvider
    }

    /// Compatibility API for tests that provide image URLs directly.
    @discardableResult
    public func export(
        imageURLs: [URL],
        ownerID: UUID,
        title: String,
        frameRate: Double = defaultFrameRate,
        narration: String? = nil
    ) async throws -> MediaAsset {
        let imageAssets = imageURLs.map {
            MediaAsset(ownerID: ownerID, kind: .painting, title: "Image", localURL: $0)
        }
        let resolvedTitle = narration?.isEmpty == false ? narration! : title
        return try await execute(
            imageAssets: imageAssets,
            ownerID: ownerID,
            title: resolvedTitle,
            frameRate: frameRate
        )
    }

    /// Renders `imageAssets` into a looping video and saves the result.
    @discardableResult
    public func execute(
        imageAssets: [MediaAsset],
        ownerID: UUID,
        title: String,
        frameRate: Double = defaultFrameRate
    ) async throws -> MediaAsset {

        // Block export under low-storage conditions.
        guard freeStorageBytesProvider() > storagePolicy.exportBlockThresholdBytes else {
            throw ExportSlideshowError.storageFull
        }

        // Validate count
        guard !imageAssets.isEmpty else { throw ExportSlideshowError.noImages }
        guard imageAssets.count <= Self.maximumImageCount else {
            throw ExportSlideshowError.tooManyImages(limit: Self.maximumImageCount)
        }

        // Validate frame rate
        guard Self.validFrameRateRange.contains(frameRate) else {
            throw ExportSlideshowError.invalidFrameRate
        }

        // Validate all image URLs exist
        let imageURLs = try imageAssets.map { asset -> URL in
            guard let url = asset.localURL else {
                throw ExportSlideshowError.imageMissing(url: "(nil)")
            }
            guard fileManager.fileExists(atPath: url.path) else {
                throw ExportSlideshowError.imageMissing(url: url.path)
            }
            return url
        }

        let outputFilename = "slideshow_\(UUID().uuidString).mp4"
        let outputURL = fileManager.temporaryDirectory.appendingPathComponent(outputFilename)

        do {
            try await renderer.render(imageURLs: imageURLs, to: outputURL, frameRate: frameRate)
        } catch {
            throw ExportSlideshowError.renderFailure(underlying: error.localizedDescription)
        }

        let estimatedDuration = Double(imageAssets.count) / frameRate
        let asset = MediaAsset(
            ownerID: ownerID,
            kind: .slideshow,
            title: title.isEmpty ? "Slideshow" : title,
            localURL: outputURL,
            durationSeconds: estimatedDuration,
            state: .saved
        )

        do {
            try await repository.save(asset)
        } catch {
            throw ExportSlideshowError.persistenceFailure(underlying: error.localizedDescription)
        }

        return asset
    }
}
