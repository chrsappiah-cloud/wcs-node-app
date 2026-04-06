//
//  SlideshowExtendedTests.swift
//  DementiaMediaTests – Unit
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Extended unit tests for ExportSlideshow covering cancellation, retry,
//  storage threshold checks, slide ordering, and narration metadata.
//

import XCTest
@testable import DementiaMedia

final class SlideshowExtendedTests: XCTestCase {

    // MARK: - Helpers

    private var fakeRenderer: FakeVideoRenderer!
    private var fakeRepo: FakeMediaRepository!
    private var fakeFileManager: FakeFileManager!
    private var sut: ExportSlideshow!
    private let patientID = UUID()
    private var registeredURLs: [URL] = []

    override func setUp() {
        super.setUp()
        fakeRenderer    = FakeVideoRenderer()
        fakeRepo        = FakeMediaRepository()
        fakeFileManager = FakeFileManager()
        sut = ExportSlideshow(
            renderer: fakeRenderer,
            repository: fakeRepo,
            fileManager: fakeFileManager
        )
    }

    override func tearDown() {
        sut = nil
        fakeRenderer = nil
        fakeRepo = nil
        fakeFileManager = nil
        registeredURLs = []
        super.tearDown()
    }

    private func makeRegisteredURL(name: String = "img") -> URL {
        let url = URL(fileURLWithPath: "/tmp/\(name)-\(UUID().uuidString).png")
        fakeFileManager.register(url)
        registeredURLs.append(url)
        return url
    }

    // MARK: - Slide ordering preserved

    func testImageOrderPreservedInRendererCall() async throws {
        let urls = ["a", "b", "c"].map { makeRegisteredURL(name: $0) }
        _ = try await sut.export(
            imageURLs: urls,
            ownerID: patientID,
            title: "Order test",
            frameRate: 1.0
        )
        XCTAssertEqual(fakeRenderer.lastImageURLs, urls)
    }

    func testReverseOrderIsAlsoPreserved() async throws {
        let urls = ["z", "y", "x"].map { makeRegisteredURL(name: $0) }
        _ = try await sut.export(
            imageURLs: urls,
            ownerID: patientID,
            title: "Reversed",
            frameRate: 1.0
        )
        XCTAssertEqual(fakeRenderer.lastImageURLs, urls)
    }

    // MARK: - Slide duration rules (via frame rate)

    func testFrameRatePassedToRendererUnchanged() async throws {
        let urls = [makeRegisteredURL()]
        _ = try await sut.export(
            imageURLs: urls,
            ownerID: patientID,
            title: "Rate test",
            frameRate: 0.5
        )
        XCTAssertEqual(fakeRenderer.lastFrameRate, 0.5, accuracy: 0.001)
    }

    func testMinimumFrameRate() async throws {
        let urls = [makeRegisteredURL()]
        _ = try await sut.export(
            imageURLs: urls, ownerID: patientID, title: "Min rate", frameRate: 0.25)
        XCTAssertEqual(fakeRenderer.lastFrameRate, 0.25, accuracy: 0.001)
    }

    func testBelowMinimumFrameRateThrows() async throws {
        let urls = [makeRegisteredURL()]
        do {
            _ = try await sut.export(
                imageURLs: urls, ownerID: patientID, title: "Too slow", frameRate: 0.1)
            XCTFail("Expected invalidFrameRate error")
        } catch ExportSlideshowError.invalidFrameRate {
            // expected
        }
    }

    func testAboveMaximumFrameRateThrows() async throws {
        let urls = [makeRegisteredURL()]
        do {
            _ = try await sut.export(
                imageURLs: urls, ownerID: patientID, title: "Too fast", frameRate: 6.0)
            XCTFail("Expected invalidFrameRate error")
        } catch ExportSlideshowError.invalidFrameRate {
            // expected
        }
    }

    // MARK: - Narration metadata (title acts as narration label)

    func testTitleStoredOnSavedAsset() async throws {
        let urls = [makeRegisteredURL()]
        let asset = try await sut.export(
            imageURLs: urls, ownerID: patientID, title: "Family Summer 2025", frameRate: 1.0)
        XCTAssertEqual(asset.title, "Family Summer 2025")
    }

    func testBlankTitleGetsAutoTitle() async throws {
        let urls = [makeRegisteredURL()]
        let asset = try await sut.export(
            imageURLs: urls, ownerID: patientID, title: "", frameRate: 1.0)
        XCTAssertFalse(asset.title.trimmingCharacters(in: .whitespaces).isEmpty,
            "A blank title should be replaced with a generated one")
    }

    // MARK: - Storage threshold (low-storage handling)

    func testStoragePolicyBlocksExportUnderThreshold() async throws {
        let policy = StorageThresholdPolicy(
            draftBlockThresholdBytes: 0,
            exportBlockThresholdBytes: Int64.max,   // always block export
            warningThresholdBytes: Int64.max
        )
        let sut2 = ExportSlideshow(
            renderer: fakeRenderer,
            repository: fakeRepo,
            fileManager: fakeFileManager,
            storagePolicy: policy,
            freeStorageBytesProvider: { 0 }         // zero free space
        )
        let urls = [makeRegisteredURL()]
        do {
            _ = try await sut2.export(
                imageURLs: urls, ownerID: patientID, title: "Low storage", frameRate: 1.0)
            XCTFail("Expected storageFull error")
        } catch ExportSlideshowError.storageFull {
            // expected
        }
    }

    func testStoragePolicyAllowsExportAboveThreshold() async throws {
        let policy = StorageThresholdPolicy(
            draftBlockThresholdBytes: 50 * 1_024 * 1_024,
            exportBlockThresholdBytes: 100 * 1_024 * 1_024,
            warningThresholdBytes: 200 * 1_024 * 1_024
        )
        let sut2 = ExportSlideshow(
            renderer: fakeRenderer,
            repository: fakeRepo,
            fileManager: fakeFileManager,
            storagePolicy: policy,
            freeStorageBytesProvider: { 1_000 * 1_024 * 1_024 }  // 1 GB free
        )
        let urls = [makeRegisteredURL()]
        let asset = try await sut2.export(
            imageURLs: urls, ownerID: patientID, title: "Enough space", frameRate: 1.0)
        XCTAssertEqual(asset.state, .saved)
    }

    // MARK: - Cancellation

    func testExportCancelledBeforeRenderDoesNotCallRepository() async {
        // Simulate cancellation by ensuring the renderer throws a cancellation error
        fakeRenderer.shouldFailWithCancellation = true
        let urls = [makeRegisteredURL()]
        do {
            _ = try await sut.export(
                imageURLs: urls, ownerID: patientID, title: "Cancelled", frameRate: 1.0)
            XCTFail("Expected cancellation error")
        } catch is CancellationError {
            XCTAssertEqual(fakeRepo.saveCallCount, 0)
        } catch {
            // CancellationError might be wrapped; we just care that repo wasn't called
            XCTAssertEqual(fakeRepo.saveCallCount, 0, "Repository must not be called after cancellation")
        }
    }

    // MARK: - Retry after failure

    func testRetryAfterRenderFailureSucceeds() async throws {
        fakeRenderer.shouldFail = true
        let urls = [makeRegisteredURL()]

        // First attempt fails
        _ = try? await sut.export(
            imageURLs: urls, ownerID: patientID, title: "Retry test", frameRate: 1.0)

        // Reset failure and retry
        fakeRenderer.shouldFail = false
        let asset = try await sut.export(
            imageURLs: urls, ownerID: patientID, title: "Retry test", frameRate: 1.0)
        XCTAssertEqual(asset.kind, .slideshow)
    }

    func testRetryCallsRendererTwiceTotal() async throws {
        fakeRenderer.shouldFail = true
        let urls = [makeRegisteredURL()]
        _ = try? await sut.export(imageURLs: urls, ownerID: patientID, title: "T", frameRate: 1)

        fakeRenderer.shouldFail = false
        _ = try await sut.export(imageURLs: urls, ownerID: patientID, title: "T", frameRate: 1)
        XCTAssertEqual(fakeRenderer.renderCallCount, 2)
    }

    // MARK: - Image count boundary

    func testExactlyMaxImagesSucceeds() async throws {
        let urls = (0..<ExportSlideshow.maximumImageCount).map { makeRegisteredURL(name: "max\($0)") }
        let asset = try await sut.export(
            imageURLs: urls, ownerID: patientID, title: "At limit", frameRate: 1.0)
        XCTAssertNotNil(asset)
    }

    func testOneOverMaxImageCountThrows() async throws {
        let urls = (0..<(ExportSlideshow.maximumImageCount + 1)).map {
            makeRegisteredURL(name: "over\($0)")
        }
        do {
            _ = try await sut.export(
                imageURLs: urls, ownerID: patientID, title: "Over limit", frameRate: 1.0)
            XCTFail("Expected tooManyImages error")
        } catch ExportSlideshowError.tooManyImages {
            // expected
        }
    }
}

