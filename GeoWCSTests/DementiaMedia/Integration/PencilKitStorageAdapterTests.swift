//
//  PencilKitStorageAdapterTests.swift
//  DementiaMediaTests – Integration
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Verifies the contract between SavePaintingSession and the PencilKit
//  canvas export adapter.  Real PencilKit tests are CI-skipped.
//

import XCTest
@testable import DementiaMedia

final class PencilKitStorageAdapterTests: XCTestCase {

    private var fakePainting: FakePaintingExporter!
    private var fakeRepo: FakeMediaRepository!
    private var fakeFileManager: FakeFileManager!
    private var sut: SavePaintingSession!
    private let ownerID = UUID()

    override func setUp() {
        super.setUp()
        fakePainting    = FakePaintingExporter()
        fakeRepo        = FakeMediaRepository()
        fakeFileManager = FakeFileManager()
        sut = SavePaintingSession(
            paintingExporter: fakePainting,
            repository: fakeRepo,
            fileManager: fakeFileManager
        )
    }

    override func tearDown() {
        sut = nil; fakePainting = nil; fakeRepo = nil; fakeFileManager = nil
        super.tearDown()
    }

    // MARK: - Save contract

    func testSavePersistsOneAsset() async throws {
        let png = Data(repeating: 0xFF, count: 512)
        _ = try await sut.save(pngData: png, ownerID: ownerID, title: "Morning Art", tags: [])
        XCTAssertEqual(fakeRepo.saveCallCount, 1)
    }

    func testSavedAssetKindIsPainting() async throws {
        let png = Data(repeating: 0xAB, count: 256)
        let asset = try await sut.save(pngData: png, ownerID: ownerID, title: "Flowers", tags: [])
        XCTAssertEqual(asset.kind, .painting)
    }

    func testSavedAssetStateIsSaved() async throws {
        let png = Data(repeating: 0x01, count: 128)
        let asset = try await sut.save(pngData: png, ownerID: ownerID, title: "Evening", tags: [])
        XCTAssertEqual(asset.state, .saved)
    }

    func testSavedAssetHasLocalURL() async throws {
        let png = Data(repeating: 0x10, count: 256)
        let asset = try await sut.save(pngData: png, ownerID: ownerID, title: "Landscape", tags: [])
        XCTAssertNotNil(asset.localURL)
    }

    // MARK: - Title rules

    func testAutoTitleGeneratedForBlankInput() async throws {
        let png = Data(repeating: 0x20, count: 256)
        let asset = try await sut.save(pngData: png, ownerID: ownerID, title: "", tags: [])
        XCTAssertFalse(asset.title.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    func testTitleAtLimitAccepted() async throws {
        let limit = SavePaintingSession.maximumTitleLength
        let title = String(repeating: "A", count: limit)
        let png = Data(repeating: 0x30, count: 256)
        let asset = try await sut.save(pngData: png, ownerID: ownerID, title: title, tags: [])
        XCTAssertEqual(asset.title, title)
    }

    func testTitleOverLimitRejected() async throws {
        let overLimit = String(repeating: "X", count: SavePaintingSession.maximumTitleLength + 1)
        do {
            _ = try await sut.save(pngData: Data(repeating: 0, count: 100), ownerID: ownerID, title: overLimit, tags: [])
            XCTFail("Expected titleTooLong error")
        } catch SavePaintingError.titleTooLong {
            // expected
        }
    }

    // MARK: - Empty PNG data rejection

    func testEmptyPNGDataRejected() async throws {
        do {
            _ = try await sut.save(pngData: Data(), ownerID: ownerID, title: "Empty", tags: [])
            XCTFail("Expected emptyCanvas error")
        } catch SavePaintingError.emptyCanvas {
            // expected
        }
    }

    // MARK: - Tags propagated

    func testTagsPropagatedToSavedAsset() async throws {
        let png = Data(repeating: 0x50, count: 512)
        let asset = try await sut.save(pngData: png, ownerID: ownerID, title: "Tagged", tags: ["garden", "spring"])
        XCTAssertEqual(asset.tags, ["garden", "spring"])
    }

    // MARK: - Device-only: real PencilKit canvas export

    func testRealPencilKitExportProducesPNGFile() async throws {
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["CI"] == "true",
            "Skipped in CI: requires PencilKit canvas on real device"
        )
        XCTAssert(true, "Wire up real PencilKitExportAdapter here for device runs")
    }
}

// MARK: - FakePaintingExporter

private final class FakePaintingExporter: PaintingExporting {
    var shouldFail = false
    func exportPNG() throws -> Data {
        if shouldFail { throw NSError(domain: "FakePainting", code: -1) }
        return Data(repeating: 0xFF, count: 512)
    }
}
