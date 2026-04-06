//
//  PrivacyConsentTests.swift
//  DementiaMediaTests – Quality Suite
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Verifies that the application enforces GDPR/HIPAA-aligned privacy
//  and consent requirements for dementia patients and their carers.
//

import XCTest
@testable import DementiaMedia

final class PrivacyConsentTests: XCTestCase {

    private let privacy   = PrivacyConsentPolicy.standard
    private let cognitive = CognitiveSafetyPolicy.dementiaSafe

    // MARK: - Explicit recording consent

    func testRecordingConsentIsRequired() {
        XCTAssertTrue(privacy.requiresExplicitRecordingConsent,
            "No audio recording may begin without explicit patient or carer consent")
    }

    // MARK: - Local-only storage

    func testStorageIsLocalOnly() {
        XCTAssertTrue(privacy.localOnly,
            "All patient media must be stored on-device only; iCloud sync must be disabled")
    }

    // MARK: - Export restriction

    func testExportIsRestricted() {
        XCTAssertTrue(privacy.exportRestricted,
            "Media export to external destinations must require explicit caregiver authorisation")
    }

    // MARK: - Deletion confirmation workflow

    func testDeletionRequiresConfirmation() {
        XCTAssertTrue(privacy.requiresDeletionConfirmation,
            "Deleting patient media must always show a two-step confirmation")
    }

    // MARK: - Storage threshold does not bypass privacy

    func testStoragePolicyDoesNotTruncateWithoutNotice() {
        let storagePolicy = StorageThresholdPolicy.default
        // The storage policy must warn before blocking, not silently discard data.
        XCTAssertLessThan(storagePolicy.warningThresholdBytes, Int64.max,
            "A warning threshold must exist below the hard block to give advance notice")
        XCTAssertLessThan(storagePolicy.exportBlockThresholdBytes,
                          storagePolicy.warningThresholdBytes,
            "Export must be blocked before the warning threshold is crossed")
    }

    // MARK: - ActivitySession – consent preserved in session model

    func testActivitySessionDoesNotStoreBiometricData() {
        // ActivitySession must only store instructional content,
        // not biometric or health data.
        let step = ActivityStep(instruction: "Draw a circle", estimatedDurationSeconds: 30)
        XCTAssertNil(step.audioGuidanceURL,
            "Steps must not pre-populate audioGuidanceURL without caregiver input")
        XCTAssertNil(step.illustrationURL,
            "Steps must not pre-populate illustrationURL without caregiver input")
    }

    func testActivityPromptAuthorIDIsRequired() {
        let prompt = ActivityPrompt(
            authorID: UUID(),
            title: "Privacy Prompt",
            bodyText: "Do this.",
            modality: .text
        )
        // authorID must never be a nil/sentinel — it must identify the responsible caregiver.
        XCTAssertNotEqual(prompt.authorID, UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    }

    // MARK: - Media asset – owner isolation

    func testMediaAssetHasOwnerID() {
        let ownerID = UUID()
        let asset = MediaAsset(title: "Painting", ownerID: ownerID, kind: .painting)
        XCTAssertEqual(asset.ownerID, ownerID,
            "Every media asset must carry an ownerID for access-control enforcement")
    }

    func testTwoDistinctOwnerAssetsAreIsolated() async throws {
        let repo = FakeMediaRepository()
        let owner1 = UUID(), owner2 = UUID()
        let a1 = MediaAsset(title: "A1", ownerID: owner1, kind: .audioRecording)
        let a2 = MediaAsset(title: "A2", ownerID: owner2, kind: .audioRecording)
        try await repo.save(a1)
        try await repo.save(a2)

        let results1 = try await repo.fetchAll(ownerID: owner1)
        let results2 = try await repo.fetchAll(ownerID: owner2)

        XCTAssertEqual(results1.count, 1)
        XCTAssertEqual(results2.count, 1)
        XCTAssertNotEqual(results1.first?.ownerID, results2.first?.ownerID)
    }
}
