//
//  AccessibilityProfileTests.swift
//  GeoWCSTests – DementiaMedia Unit Tests
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Verifies AccessibilityProfile defaults, equality, and boundary values.
//

import XCTest
@testable import DementiaMedia

final class AccessibilityProfileTests: XCTestCase {

    // MARK: - Default values

    func testDefaultMinimumTapTargetIsAtLeast44Pts() {
        let profile = AccessibilityProfile.default
        XCTAssertGreaterThanOrEqual(profile.minimumTapTargetPts, 44,
            "Minimum tap target must meet Apple HIG minimum of 44 pt")
    }

    func testDefaultFontScaleAboveOne() {
        XCTAssertGreaterThan(AccessibilityProfile.default.fontScaleMultiplier, 1.0)
    }

    func testDefaultContrastModeIsHigh() {
        XCTAssertEqual(AccessibilityProfile.default.contrastMode, .high)
    }

    func testDefaultSimplifiedLayoutIsTrue() {
        XCTAssertTrue(AccessibilityProfile.default.simplifiedLayout)
    }

    func testDefaultVoiceSpeedIsBelowNormal() {
        // Calmer-than-normal speech for dementia patients
        XCTAssertLessThan(AccessibilityProfile.default.voiceSpeed, 1.0)
        XCTAssertGreaterThan(AccessibilityProfile.default.voiceSpeed, 0.0)
    }

    func testDefaultUsesLargeBrush() {
        XCTAssertTrue(AccessibilityProfile.default.useLargeBrushByDefault)
    }

    // MARK: - Custom construction

    func testCustomProfilePreservesAllFields() {
        let profile = AccessibilityProfile(
            minimumTapTargetPts: 80,
            fontScaleMultiplier: 1.6,
            contrastMode: .veryHigh,
            simplifiedLayout: false,
            voiceSpeed: 1.0,
            useLargeBrushByDefault: false,
            hapticFeedbackEnabled: false
        )
        XCTAssertEqual(profile.minimumTapTargetPts, 80)
        XCTAssertEqual(profile.fontScaleMultiplier, 1.6)
        XCTAssertEqual(profile.contrastMode, .veryHigh)
        XCTAssertFalse(profile.simplifiedLayout)
        XCTAssertEqual(profile.voiceSpeed, 1.0)
        XCTAssertFalse(profile.useLargeBrushByDefault)
        XCTAssertFalse(profile.hapticFeedbackEnabled)
    }

    // MARK: - Equality

    func testTwoDefaultProfilesAreEqual() {
        XCTAssertEqual(AccessibilityProfile.default, AccessibilityProfile.default)
    }

    func testProfilesWithDifferentTapTargetAreNotEqual() {
        var modified = AccessibilityProfile.default
        modified.minimumTapTargetPts = 100
        XCTAssertNotEqual(AccessibilityProfile.default, modified)
    }

    // MARK: - Codable round-trip

    func testProfileSurvivesJSONRoundTrip() throws {
        let original = AccessibilityProfile.default
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(AccessibilityProfile.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testProfileDecodesFromFixture() throws {
        let decoded = try FixtureLoader.decode(AccessibilityProfile.self, named: "accessibility_profile.json")

        XCTAssertEqual(decoded.minimumTapTargetPts, 72)
        XCTAssertEqual(decoded.fontScaleMultiplier, 1.4)
        XCTAssertEqual(decoded.contrastMode, .veryHigh)
        XCTAssertTrue(decoded.simplifiedLayout)
        XCTAssertEqual(decoded.voiceSpeed, 0.9)
        XCTAssertFalse(decoded.useLargeBrushByDefault)
        XCTAssertTrue(decoded.hapticFeedbackEnabled)
    }

    func testMalformedProfileFixtureFailsToDecodeWithExpectedError() {
        XCTAssertThrowsError(
            try FixtureLoader.decode(AccessibilityProfile.self, named: "accessibility_profile_malformed.json")
        ) { error in
            guard case FixtureLoader.FixtureError.failedToDecode(let name) = error else {
                return XCTFail("Expected failedToDecode error")
            }
            XCTAssertEqual(name, "accessibility_profile_malformed.json")
        }
    }
}
