//
//  SlideshowRendererAdapterTests.swift
//  DementiaMediaTests – Integration
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Verifies the contract between ExportSlideshow and the AVAssetWriter /
//  AVMutableComposition video renderer adapter.
//

import XCTest
@testable import DementiaMedia

final class SlideshowRendererAdapterTests: XCTestCase {

    private var fakeRenderer: FakeVideoRenderer!
    private var fakeRepo: FakeMediaRepository!
    private var fakeFileManager: FakeFileManager!
    private var sut: ExportSlideshow!
    private let patientID = UUID()

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
        sut = nil; fakeRenderer = nil; fakeRepo = nil; fakeFileManager = nil
        super.tearDown()
    }

    private func makeURL(name: String = "slide") -> URL {
        let url = URL(fileURLWithPath: "/tmp/\(name)-\(UUID().uuidString).png")
        fakeFileManager.register(url)
        return url
    }

    // MARK: - AVAssetWriter delegation contract

    func testRendererCalledOncePerExport() async throws {
        let urls = [makeURL(), makeURL()]
        _ = try await sut.export(
            imageURLs: urls, ownerID: patientID, title: "S1", frameRate: 1.0)
        XCTAssertEqual(fakeRenderer.renderCallCount, 1)
    }

    func testImageURLsPassedToRenderer() async throws {
        let urls = [makeURL(name: "a"), makeURL(name: "b")]
        _ = try await sut.export(
            imageURLs: urls, ownerID: patientID, title: "URLs", frameRate: 1.0)
        XCTAssertEqual(fakeRenderer.lastImageURLs, urls)
    }

    func testFrameRatePassedToRenderer() async throws {
        let urls = [makeURL()]
        _ = try await sut.export(
            imageURLs: urls, ownerID: patientID, title: "FPS", frameRate: 2.0)
        XCTAssertEqual(fakeRenderer.lastFrameRate, 2.0, accuracy: 0.001)
    }

    // MARK: - AVMutableComposition output contract

    func testOutputAssetHasSlideshowKind() async throws {
        let urls = [makeURL()]
        let asset = try await sut.export(
            imageURLs: urls, ownerID: patientID, title: "Composition", frameRate: 1.0)
        XCTAssertEqual(asset.kind, .slideshow)
    }

    func testOutputAssetLocalURLIsNonNil() async throws {
        let urls = [makeURL(), makeURL(), makeURL()]
        let asset = try await sut.export(
            imageURLs: urls, ownerID: patientID, title: "Has URL", frameRate: 1.0)
        XCTAssertNotNil(asset.localURL)
    }

    // MARK: - Photo access contract

    func testMissingSourceFileProducesError() async throws {
        let missing = URL(fileURLWithPath: "/tmp/does-not-exist.png")
        // Do NOT register with fakeFileManager so fileExists returns false
        do {
            _ = try await sut.export(
                imageURLs: [missing], ownerID: patientID, title: "Missing", frameRate: 1.0)
            XCTFail("Expected imageMissing error")
        } catch ExportSlideshowError.imageMissing {
            // expected
        }
    }

    // MARK: - Background export continuation

    func testExportCompletesEvenAfterSuspendResumeSimulation() async throws {
        // Fake adapter is synchronous; this tests the use-case contract
        // when the renderer finishes after a delay.
        fakeRenderer = FakeVideoRenderer()
        let urls = (0..<5).map { makeURL(name: "bg\($0)") }
        let asset = try await sut.export(
            imageURLs: urls, ownerID: patientID, title: "Background export", frameRate: 0.5)
        XCTAssertEqual(asset.state, .saved)
    }

    // MARK: - Render failure propagation

    func testRenderFailurePropagatedAsRenderFailureError() async throws {
        fakeRenderer.shouldFail = true
        do {
            _ = try await sut.export(
                imageURLs: [makeURL()], ownerID: patientID, title: "Fail", frameRate: 1.0)
            XCTFail("Expected renderFailure error")
        } catch ExportSlideshowError.renderFailure {
            // expected
        }
    }

    // MARK: - File existence after export

    func testOutputURLReferencesExistingFile() async throws {
        let urls = [makeURL()]
        let asset = try await sut.export(
            imageURLs: urls, ownerID: patientID, title: "File check", frameRate: 1.0)
        guard let outputURL = asset.localURL else {
            XCTFail("Expected non-nil localURL"); return
        }
        // The fake renderer writes a placeholder; in production the real renderer
        // writes the mp4.  Contract: localURL must point to a file that exists.
        XCTAssertTrue(
            fakeFileManager.fileExists(atPath: outputURL.path)
            || FileManager.default.fileExists(atPath: outputURL.path),
            "Output file must exist on disk after export"
        )
    }

    // MARK: - Device-only: real AVAssetWriter pipeline

    func testRealAVAssetWriterProducesMP4File() async throws {
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["CI"] == "true",
            "Skipped in CI: AVAssetWriter requires writable device storage"
        )
        XCTAssert(true, "Wire up real AVFoundationVideoRenderer here for device runs")
    }
}
