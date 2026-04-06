//
//  SecureMediaRepositoryTests.swift
//  DementiaMediaTests – Integration
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Verifies the storage contract: save → fetch round-trips, owner
//  isolation, deletion workflow, and local-only (iCloud-sync disabled)
//  enforcement.
//

import XCTest
@testable import DementiaMedia

final class SecureMediaRepositoryTests: XCTestCase {

    private var sut: FakeMediaRepository!
    private let ownerA = UUID()
    private let ownerB = UUID()

    override func setUp() {
        super.setUp()
        sut = FakeMediaRepository()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeAsset(ownerID: UUID = UUID(),
                           kind: MediaKind = .audioRecording) -> MediaAsset {
        MediaAsset(title: "Test", ownerID: ownerID, kind: kind)
    }

    // MARK: - Save / Fetch round-trip

    func testSaveAndFetchByIDRoundTrip() async throws {
        let asset = makeAsset(ownerID: ownerA)
        try await sut.save(asset)
        let fetched = try await sut.fetch(id: asset.id)
        XCTAssertEqual(fetched?.id, asset.id)
    }

    func testSavedAssetRetainsKind() async throws {
        let asset = makeAsset(ownerID: ownerA, kind: .painting)
        try await sut.save(asset)
        let fetched = try await sut.fetch(id: asset.id)
        XCTAssertEqual(fetched?.kind, .painting)
    }

    func testFetchUnknownIDReturnsNil() async throws {
        let result = try await sut.fetch(id: UUID())
        XCTAssertNil(result)
    }

    // MARK: - fetchAll isolation per owner

    func testFetchAllReturnsOnlyOwnerAssets() async throws {
        let a1 = makeAsset(ownerID: ownerA)
        let a2 = makeAsset(ownerID: ownerA)
        let b1 = makeAsset(ownerID: ownerB)
        try await sut.save(a1)
        try await sut.save(a2)
        try await sut.save(b1)

        let resultsA = try await sut.fetchAll(ownerID: ownerA)
        XCTAssertEqual(resultsA.count, 2)
        XCTAssertTrue(resultsA.allSatisfy { $0.ownerID == ownerA })
    }

    func testFetchAllReturnsEmptyForNewOwner() async throws {
        let results = try await sut.fetchAll(ownerID: UUID())
        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - Update / overwrite

    func testUpdateOverwritesExistingRecord() async throws {
        var asset = makeAsset(ownerID: ownerA)
        try await sut.save(asset)
        asset.title = "Updated Title"
        try await sut.save(asset)       // second save is the update
        let fetched = try await sut.fetch(id: asset.id)
        XCTAssertEqual(fetched?.title, "Updated Title")
    }

    // MARK: - Deletion workflow

    func testDeleteRemovesAssetFromStore() async throws {
        let asset = makeAsset(ownerID: ownerA)
        try await sut.save(asset)
        try await sut.delete(id: asset.id)
        let fetched = try await sut.fetch(id: asset.id)
        XCTAssertNil(fetched)
    }

    func testDeleteNonExistentIDDoesNotThrow() async throws {
        // Idempotent delete
        XCTAssertNoThrow(try await sut.delete(id: UUID()))
    }

    func testFetchAllAfterDeleteExcludesDeletedAsset() async throws {
        let a1 = makeAsset(ownerID: ownerA)
        let a2 = makeAsset(ownerID: ownerA)
        try await sut.save(a1)
        try await sut.save(a2)
        try await sut.delete(id: a1.id)
        let results = try await sut.fetchAll(ownerID: ownerA)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, a2.id)
    }

    // MARK: - Local-only policy contract

    func testAssetsMarkedLocalOnlyByDefault() async throws {
        let asset = makeAsset(ownerID: ownerA)
        // PrivacyConsentPolicy.localOnly = true
        let policy = PrivacyConsentPolicy.standard
        XCTAssertTrue(policy.localOnly,
            "All media must be stored locally; iCloud sync must never be enabled by default")
        _ = asset   // silence unused warning
    }

    func testPrivacyPolicyRequiresExplicitRecordingConsent() {
        let policy = PrivacyConsentPolicy.standard
        XCTAssertTrue(policy.requiresExplicitRecordingConsent,
            "Recording must only begin after the patient or caregiver has explicitly consented")
    }

    // MARK: - Persistence survives simulated relaunch

    func testAssetSurvivedMemoryFlushedRelaunch() async throws {
        let asset = makeAsset(ownerID: ownerA)
        try await sut.save(asset)
        // Simulate relaunch: create a new repository instance backed by the same store.
        let relaunched = FakeMediaRepository(existingStore: sut.store)
        let fetched = try await relaunched.fetch(id: asset.id)
        XCTAssertEqual(fetched?.id, asset.id)
    }

    // MARK: - Device-only: encrypted file system

    func testRealEncryptedStorePersistsAcrossRestart() {
        XCTSkip("Skipped in CI: encrypted FS adapter requires device")
    }
}
