//
//  MediaRepositoryIntegrationTests.swift
//  GeoWCSTests – DementiaMedia Integration Tests
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Tests the repository contract using FakeMediaRepository.
//  Also documents expectations for a file-backed real implementation.
//

import XCTest
@testable import DementiaMedia

final class MediaRepositoryIntegrationTests: XCTestCase {

    private var repository: FakeMediaRepository!
    private let ownerID = UUID()

    override func setUp() {
        super.setUp()
        repository = FakeMediaRepository()
    }

    // MARK: - Save + Fetch

    func testSaveAndFetchRoundTrip() async throws {
        let asset = MediaAsset(ownerID: ownerID, kind: .painting, title: "Sunset")
        try await repository.save(asset)
        let fetched = try await repository.fetch(id: asset.id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.title, "Sunset")
    }

    func testFetchMissingIDReturnsNil() async throws {
        let fetched = try await repository.fetch(id: UUID())
        XCTAssertNil(fetched)
    }

    func testFetchAllReturnsAllAssetsForOwner() async throws {
        let a1 = MediaAsset(ownerID: ownerID, kind: .painting, title: "One")
        let a2 = MediaAsset(ownerID: ownerID, kind: .audioPrompt, title: "Two")
        let a3 = MediaAsset(ownerID: UUID(), kind: .painting, title: "Other owner")
        try await repository.save(a1)
        try await repository.save(a2)
        try await repository.save(a3)

        let results = try await repository.fetchAll(ownerID: ownerID)
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.ownerID == ownerID })
    }

    // MARK: - Update

    func testUpdateChangesTitle() async throws {
        var asset = MediaAsset(ownerID: ownerID, kind: .painting, title: "Original")
        try await repository.save(asset)
        asset.title = "Updated"
        try await repository.update(asset)
        let fetched = try await repository.fetch(id: asset.id)
        XCTAssertEqual(fetched?.title, "Updated")
    }

    func testUpdateChangesState() async throws {
        var asset = MediaAsset(ownerID: ownerID, kind: .slideshow, title: "Video")
        try await repository.save(asset)
        asset.state = .exported
        try await repository.update(asset)
        let fetched = try await repository.fetch(id: asset.id)
        XCTAssertEqual(fetched?.state, .exported)
    }

    // MARK: - Delete

    func testDeleteRemovesAssetFromRepository() async throws {
        let asset = MediaAsset(ownerID: ownerID, kind: .memoryRecording, title: "ToDelete")
        try await repository.save(asset)
        try await repository.delete(id: asset.id)
        let fetched = try await repository.fetch(id: asset.id)
        XCTAssertNil(fetched)
    }

    func testFetchAllAfterDeleteReturnsReducedCount() async throws {
        let a1 = MediaAsset(ownerID: ownerID, kind: .painting, title: "Keep")
        let a2 = MediaAsset(ownerID: ownerID, kind: .painting, title: "Remove")
        try await repository.save(a1)
        try await repository.save(a2)
        try await repository.delete(id: a2.id)

        let results = try await repository.fetchAll(ownerID: ownerID)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Keep")
    }

    // MARK: - Persistence failure handling

    func testSaveFailureThrowsAndDoesNotMutateStore() async {
        repository.shouldFailOnSave = true
        let asset = MediaAsset(ownerID: ownerID, kind: .painting, title: "Bad save")
        do {
            try await repository.save(asset)
            XCTFail("Expected error on save")
        } catch {
            let all = try! await repository.fetchAll(ownerID: ownerID)
            XCTAssertTrue(all.isEmpty)
        }
    }

    // MARK: - Asset kind coverage

    func testAllMediaKindsCanBePersistedAndFetched() async throws {
        let kinds: [MediaKind] = [.painting, .audioPrompt, .memoryRecording,
                                   .videoMemory, .slideshow, .importedPhoto]
        for kind in kinds {
            let asset = MediaAsset(ownerID: ownerID, kind: kind, title: kind.rawValue)
            try await repository.save(asset)
            let fetched = try await repository.fetch(id: asset.id)
            XCTAssertEqual(fetched?.kind, kind, "Kind \(kind.rawValue) failed round-trip")
        }
    }

    func testFixtureDecodedMediaAssetCanBeSavedAndFetched() async throws {
        let asset = try FixtureLoader.decode(MediaAsset.self, named: "media_asset.json")

        try await repository.save(asset)
        let fetched = try await repository.fetch(id: asset.id)

        XCTAssertEqual(fetched, asset)
    }

    func testMalformedMediaAssetFixtureFailsToDecodeWithExpectedError() {
        XCTAssertThrowsError(
            try FixtureLoader.decode(MediaAsset.self, named: "media_asset_malformed.json")
        ) { error in
            guard case FixtureLoader.FixtureError.failedToDecode(let name) = error else {
                return XCTFail("Expected failedToDecode error")
            }
            XCTAssertEqual(name, "media_asset_malformed.json")
        }
    }

    // MARK: - Real FileManagerRepository contract documentation

    func testFileManagerRepositoryPersistsAcrossInstanceRestarts() throws {
        try XCTSkipIf(true, "Manual/device test: verifies on-disk JSON persistence")
        // Documentation expectations:
        // 1. save() writes to a deterministic directory in the app sandbox
        // 2. fetchAll() after app restart returns previously saved assets
        // 3. delete() removes the physical file as well as the index entry
        // 4. Assets with non-nil localURL have their files accessible at that path
    }
}
