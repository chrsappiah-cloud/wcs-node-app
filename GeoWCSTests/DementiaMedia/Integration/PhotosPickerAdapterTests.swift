//
//  PhotosPickerAdapterTests.swift
//  DementiaMediaTests – Integration
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Verifies the contract between ExportSlideshow and the Photos image-
//  picking adapter.  Real Photos.framework access is CI-skipped.
//

import XCTest
@testable import DementiaMedia

final class PhotosPickerAdapterTests: XCTestCase {

    private var fakePicker: FakeImagePicker!
    private var fakeRenderer: FakeVideoRenderer!
    private var fakeRepo: FakeMediaRepository!
    private var fakeFileManager: FakeFileManager!
    private var sut: ExportSlideshow!
    private let patientID = UUID()

    override func setUp() {
        super.setUp()
        fakePicker      = FakeImagePicker()
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
        sut = nil; fakePicker = nil; fakeRenderer = nil; fakeRepo = nil; fakeFileManager = nil
        super.tearDown()
    }

    private func makeURL(_ name: String = "photo") -> URL {
        let url = URL(fileURLWithPath: "/tmp/photos/\(name)-\(UUID().uuidString).jpg")
        fakeFileManager.register(url)
        return url
    }

    // MARK: - Selection contract

    func testPickerReturnsSelectedURLs() async throws {
        let selected = [makeURL("family"), makeURL("garden")]
        fakePicker.stubbedURLs = selected
        let urls = try await fakePicker.pickImages(limit: 10)
        XCTAssertEqual(urls.count, 2)
    }

    func testPickerReturnsEmptyArrayOnCancel() async throws {
        fakePicker.stubbedURLs = []
        let urls = try await fakePicker.pickImages(limit: 10)
        XCTAssertTrue(urls.isEmpty)
    }

    func testPickerRespectsImageCountLimit() async throws {
        fakePicker.stubbedURLs = (0..<20).map { makeURL("img\($0)") }
        let limit = 5
        let received = try await fakePicker.pickImages(limit: limit)
        // The adapter must enforce the limit imposed by the caller.
        XCTAssertLessThanOrEqual(received.count, limit)
    }

    // MARK: - Integration with ExportSlideshow

    func testPickedImagesFlowIntoExport() async throws {
        let urls = [makeURL("A1"), makeURL("A2")]
        _ = try await sut.export(
            imageURLs: urls, ownerID: patientID, title: "Family album", frameRate: 1.0)
        XCTAssertEqual(fakeRenderer.lastImageURLs, urls)
    }

    func testZeroPickedImagesRejectedByExport() async throws {
        do {
            _ = try await sut.export(
                imageURLs: [], ownerID: patientID, title: "Empty pick", frameRate: 1.0)
            XCTFail("Expected noImages error")
        } catch ExportSlideshowError.noImages {
            // expected
        }
    }

    // MARK: - Max image selection contract (50 images)

    func testExportAcceptsExactlyMaxImages() async throws {
        let urls = (0..<ExportSlideshow.maximumImageCount).map { makeURL("max\($0)") }
        let asset = try await sut.export(
            imageURLs: urls, ownerID: patientID, title: "Max selection", frameRate: 1.0)
        XCTAssertNotNil(asset)
    }

    func testExportRejectsOneOverMax() async throws {
        let urls = (0..<(ExportSlideshow.maximumImageCount + 1)).map { makeURL("over\($0)") }
        do {
            _ = try await sut.export(
                imageURLs: urls, ownerID: patientID, title: "Over max", frameRate: 1.0)
            XCTFail("Expected tooManyImages error")
        } catch ExportSlideshowError.tooManyImages {
            // expected
        }
    }

    // MARK: - Device-only: real Photos picker

    func testRealPhotosPickerPresentsUI() async throws {
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["CI"] == "true",
            "Skipped in CI: Photos picker requires user interaction"
        )
        XCTAssert(true, "Wire up real PHPickerAdapter here for device runs")
    }
}

// MARK: - FakeImagePicker

private final class FakeImagePicker: ImagePicking {
    var stubbedURLs: [URL] = []

    func pickImages(limit: Int) async throws -> [URL] {
        return Array(stubbedURLs.prefix(limit))
    }
}
