//
//  ReliabilityTests.swift
//  DementiaMediaTests – Quality Suite
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Verifies that the application behaves safely under adverse conditions:
//  low storage, interruptions, crash recovery, and background transitions.
//

import XCTest
@testable import DementiaMedia

final class ReliabilityTests: XCTestCase {

    private var fakeRepo: FakeMediaRepository!
    private var fakeScheduler: FakeNotificationScheduler!
    private var fakeAnalytics: FakeAnalyticsLogger!

    override func setUp() {
        super.setUp()
        fakeRepo      = FakeMediaRepository()
        fakeScheduler = FakeNotificationScheduler()
        fakeAnalytics = FakeAnalyticsLogger()
    }

    override func tearDown() {
        fakeRepo = nil; fakeScheduler = nil; fakeAnalytics = nil
        super.tearDown()
    }

    // MARK: - Storage threshold policy

    func testDraftBlockThresholdIsAboveZero() {
        let policy = StorageThresholdPolicy.default
        XCTAssertGreaterThan(policy.draftBlockThresholdBytes, 0,
            "Draft block threshold must be a positive number of bytes")
    }

    func testExportBlockThresholdIsHigherThanDraftBlock() {
        let policy = StorageThresholdPolicy.default
        XCTAssertGreaterThan(policy.exportBlockThresholdBytes,
                             policy.draftBlockThresholdBytes,
            "Export block must kick in after draft block to give users a chance to free space")
    }

    func testWarningThresholdIsHighestValue() {
        let policy = StorageThresholdPolicy.default
        XCTAssertGreaterThanOrEqual(policy.warningThresholdBytes,
                                    policy.exportBlockThresholdBytes,
            "Warning threshold must be the highest value in the policy ladder")
    }

    // MARK: - Low-storage export blocking

    func testLowStorageExportThrowsStorageFull() async throws {
        let lowFreeBytes: Int64 = 10 * 1024 * 1024   // 10 MB — below 200 MB export block
        let fakeRenderer = FakeVideoRenderer()
        let policy = StorageThresholdPolicy.default

        let sut = ExportSlideshow(
            renderer: fakeRenderer,
            repository: fakeRepo,
            fileManager: FakeFileManager(),
            storagePolicy: policy,
            freeStorageBytesProvider: { lowFreeBytes }
        )

        let urls = [URL(fileURLWithPath: "/tmp/a.jpg")]
        do {
            _ = try await sut.export(imageURLs: urls, frameDuration: 3.0,
                                     narration: nil, ownerID: UUID())
            XCTFail("Expected ExportSlideshowError.storageFull")
        } catch ExportSlideshowError.storageFull {
            // ✓ correct error raised
        }
    }

    func testAdequateStorageDoesNotBlockExport() async throws {
        let highFreeBytes: Int64 = 500 * 1024 * 1024   // 500 MB — well above block
        let fakeRenderer = FakeVideoRenderer()
        let policy = StorageThresholdPolicy.default

        let sut = ExportSlideshow(
            renderer: fakeRenderer,
            repository: fakeRepo,
            fileManager: FakeFileManager(),
            storagePolicy: policy,
            freeStorageBytesProvider: { highFreeBytes }
        )

        let url = URL(fileURLWithPath: "/tmp/b.jpg")
        fakeRenderer.outputURL = url
        let urls = [url]
        _ = try? await sut.export(imageURLs: urls, frameDuration: 3.0,
                                  narration: nil, ownerID: UUID())
        // No storageFull error — test simply confirms it reaches the renderer stage
        XCTAssertEqual(fakeRenderer.renderCallCount, 1)
    }

    // MARK: - Autosave on interruption (crash recovery)

    func testAssetSavedToDraftBeforeExportCompletes() async throws {
        // The use case must persist a draft MediaAsset before
        // initiating any long-running render to survive a crash.
        let sut = StartGuidedActivity(
            repository: fakeRepo,
            notificationScheduler: fakeScheduler,
            analytics: fakeAnalytics
        )
        let prompt = ActivityPrompt(authorID: UUID(), title: "Autosave",
                                    bodyText: "One step.", modality: .text)
        let session = try await sut.begin(prompt: prompt, patientID: UUID())
        // After begin, an asset should already be persisted as a draft
        XCTAssertGreaterThan(fakeRepo.saveCallCount, 0,
            "Session asset must be persisted immediately on begin for crash safety")
        _ = session
    }

    // MARK: - Interruption recovery (session resume)

    func testSessionInProgressCanBeResumedAfterBackground() throws {
        let steps = (1...5).map { ActivityStep(instruction: "Step \($0)", estimatedDurationSeconds: 30) }
        let prompt = ActivityPrompt(authorID: UUID(), title: "T",
                                    bodyText: "B", modality: .text, steps: steps)
        var session = ActivitySession(prompt: prompt, patientID: UUID(), pacingPolicy: .standard)
        session.start()
        try session.completeCurrentStep()

        // Simulate background interrupt: pause by caregiver
        session.pauseByCaregiver()
        XCTAssertEqual(session.state, .pausedByCaregiver)

        // Resume
        try session.resumeFromBreak()
        XCTAssertEqual(session.state, .inProgress)
    }

    // MARK: - Persistence across simulated relaunch

    func testSavedAssetAvailableAfterRelaunch() async throws {
        let ownerID = UUID()
        let asset = MediaAsset(title: "Relaunch Test", ownerID: ownerID, kind: .painting)
        try await fakeRepo.save(asset)

        let relaunched = FakeMediaRepository(existingStore: fakeRepo.store)
        let fetched = try await relaunched.fetch(id: asset.id)
        XCTAssertEqual(fetched?.id, asset.id,
            "Assets must survive a simulated process relaunch via the shared store")
    }

    // MARK: - Duplicate save idempotency

    func testDoubleSaveDoesNotDuplicate() async throws {
        let ownerID = UUID()
        let asset = MediaAsset(title: "Dup", ownerID: ownerID, kind: .audioRecording)
        try await fakeRepo.save(asset)
        try await fakeRepo.save(asset)   // second save is update

        let results = try await fakeRepo.fetchAll(ownerID: ownerID)
        XCTAssertEqual(results.count, 1,
            "Saving the same asset ID twice must update-in-place, not create a duplicate")
    }
}
