//
//  ExportSlideshowTests.swift
//  GeoWCSTests – DementiaMedia Unit Tests
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Unit tests for ExportSlideshow use case.
//  Covers: image validation, frame-rate policy, render delegation, persistence.
//

import XCTest
@testable import DementiaMedia

final class ExportSlideshowTests: XCTestCase {

    private var renderer: FakeVideoRenderer!
    private var repository: FakeMediaRepository!
    private var fileManager: FakeFileManager!
    private var sut: ExportSlideshow!

    private let ownerID = UUID()

    override func setUp() {
        super.setUp()
        renderer    = FakeVideoRenderer()
        repository  = FakeMediaRepository()
        fileManager = FakeFileManager()
        sut = ExportSlideshow(renderer: renderer,
                              repository: repository,
                              fileManager: fileManager)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeImageAsset(idx: Int = 0) -> MediaAsset {
        let url = fileManager.temporaryDirectory.appendingPathComponent("img\(idx).png")
        fileManager.register(url)  // mark as existing
        return MediaAsset(ownerID: ownerID, kind: .painting, title: "Image \(idx)", localURL: url)
    }

    // MARK: - Happy path

    func testValidSlideshowSavesAsset() async throws {
        let images = (0..<3).map { makeImageAsset(idx: $0) }
        let asset = try await sut.execute(imageAssets: images, ownerID: ownerID, title: "Holiday")

        XCTAssertEqual(asset.kind, .slideshow)
        XCTAssertEqual(asset.ownerID, ownerID)
        XCTAssertEqual(asset.state, .saved)
        XCTAssertEqual(repository.saveCallCount, 1)
    }

    func testRendererReceivesCorrectImageURLs() async throws {
        let images = (0..<4).map { makeImageAsset(idx: $0) }
        _ = try await sut.execute(imageAssets: images, ownerID: ownerID, title: "Family")

        XCTAssertEqual(renderer.lastImageURLs.count, 4)
        XCTAssertEqual(renderer.renderCallCount, 1)
    }

    func testDefaultFrameRateIsPassedToRenderer() async throws {
        let images = [makeImageAsset()]
        _ = try await sut.execute(imageAssets: images, ownerID: ownerID, title: "Single")
        XCTAssertEqual(renderer.lastFrameRate, ExportSlideshow.defaultFrameRate)
    }

    func testCustomFrameRateIsRespected() async throws {
        let images = [makeImageAsset()]
        _ = try await sut.execute(imageAssets: images, ownerID: ownerID,
                                   title: "Fast", frameRate: 2.0)
        XCTAssertEqual(renderer.lastFrameRate, 2.0, accuracy: 0.001)
    }

    func testDurationIsCalculatedCorrectly() async throws {
        let images = (0..<10).map { makeImageAsset(idx: $0) }
        let asset = try await sut.execute(imageAssets: images, ownerID: ownerID,
                                           title: "10 images at 2fps", frameRate: 2.0)
        XCTAssertEqual(asset.durationSeconds, 5.0, accuracy: 0.001) // 10 / 2
    }

    // MARK: - Validation errors

    func testEmptyImageListThrows() async {
        do {
            _ = try await sut.execute(imageAssets: [], ownerID: ownerID, title: "Empty")
            XCTFail("Expected noImages error")
        } catch let err as ExportSlideshowError {
            XCTAssertEqual(err, .noImages)
        }
    }

    func testTooManyImagesThrows() async {
        let images = (0..<(ExportSlideshow.maximumImageCount + 1))
            .map { makeImageAsset(idx: $0) }
        do {
            _ = try await sut.execute(imageAssets: images, ownerID: ownerID, title: "Overflow")
            XCTFail("Expected tooManyImages error")
        } catch let err as ExportSlideshowError {
            if case .tooManyImages(let limit) = err {
                XCTAssertEqual(limit, ExportSlideshow.maximumImageCount)
            } else {
                XCTFail("Wrong error: \(err)")
            }
        }
    }

    func testExactlyMaximumImagesSucceeds() async throws {
        let images = (0..<ExportSlideshow.maximumImageCount)
            .map { makeImageAsset(idx: $0) }
        let asset = try await sut.execute(imageAssets: images, ownerID: ownerID, title: "Max")
        XCTAssertEqual(asset.kind, .slideshow)
    }

    func testFrameRateBelowMinimumThrows() async {
        do {
            _ = try await sut.execute(imageAssets: [makeImageAsset()], ownerID: ownerID,
                                       title: "Slow", frameRate: 0.1)
            XCTFail("Expected invalidFrameRate error")
        } catch let err as ExportSlideshowError {
            XCTAssertEqual(err, .invalidFrameRate)
        }
    }

    func testFrameRateAboveMaximumThrows() async {
        do {
            _ = try await sut.execute(imageAssets: [makeImageAsset()], ownerID: ownerID,
                                       title: "Fast", frameRate: 10.0)
            XCTFail("Expected invalidFrameRate error")
        } catch let err as ExportSlideshowError {
            XCTAssertEqual(err, .invalidFrameRate)
        }
    }

    func testMissingImageFileThrows() async {
        var asset = MediaAsset(ownerID: ownerID, kind: .painting, title: "Missing",
                               localURL: URL(fileURLWithPath: "/tmp/does_not_exist.png"))
        // Do NOT register in fileManager
        do {
            _ = try await sut.execute(imageAssets: [asset], ownerID: ownerID, title: "Ghost")
            XCTFail("Expected imageMissing error")
        } catch let err as ExportSlideshowError {
            if case .imageMissing = err { /* expected */ } else {
                XCTFail("Wrong error: \(err)")
            }
        }
    }

    func testNilImageURLThrows() async {
        let asset = MediaAsset(ownerID: ownerID, kind: .painting, title: "NoURL")
        do {
            _ = try await sut.execute(imageAssets: [asset], ownerID: ownerID, title: "Nil URL")
            XCTFail("Expected imageMissing error")
        } catch let err as ExportSlideshowError {
            if case .imageMissing = err { /* expected */ } else {
                XCTFail("Wrong error: \(err)")
            }
        }
    }

    // MARK: - Render failure

    func testRenderFailureThrowsCorrectError() async {
        renderer.shouldFail = true
        let images = [makeImageAsset()]
        do {
            _ = try await sut.execute(imageAssets: images, ownerID: ownerID, title: "Broken")
            XCTFail("Expected renderFailure error")
        } catch let err as ExportSlideshowError {
            if case .renderFailure = err { /* expected */ } else {
                XCTFail("Wrong error: \(err)")
            }
        }
    }

    func testRenderFailureDoesNotSaveToRepository() async {
        renderer.shouldFail = true
        _ = try? await sut.execute(imageAssets: [makeImageAsset()], ownerID: ownerID, title: "x")
        XCTAssertEqual(repository.saveCallCount, 0)
    }

    // MARK: - Repository failure

    func testRepositoryFailureThrowsPersistenceError() async {
        repository.shouldFailOnSave = true
        do {
            _ = try await sut.execute(imageAssets: [makeImageAsset()],
                                       ownerID: ownerID, title: "Persist fail")
            XCTFail("Expected persistenceFailure error")
        } catch let err as ExportSlideshowError {
            if case .persistenceFailure = err { /* expected */ } else {
                XCTFail("Wrong error: \(err)")
            }
        }
    }
}
