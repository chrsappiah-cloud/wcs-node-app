//
//  DeArtsWCSSeedModeIntegrationTests.swift
//  GeoWCSTests - RokMax (DeArtsWCS) Integration Tests
//
//  Verifies deterministic seed state used for UI test mode.
//

import XCTest
@testable import GeoWCS

final class DeArtsWCSSeedModeIntegrationTests: XCTestCase {

    func testUITestMode_seedsDeterministicModelState() {
        let model = AppModel(uiTestMode: true)

        XCTAssertEqual(model.statusMessage, "Session Started")
        XCTAssertEqual(model.selectedTab, .home)
        XCTAssertFalse(model.isOfflineMode)
        XCTAssertEqual(model.moodValue, 0.5)

        XCTAssertEqual(model.generatedImages.count, 1)
        XCTAssertEqual(model.capturedPhotos.count, 1)
        XCTAssertEqual(model.savedPaintings.count, 1)
        XCTAssertEqual(model.linkedMemories.count, 3)
    }

    func testStandardMode_doesNotSeedDeterministicState() {
        let model = AppModel(uiTestMode: false)

        XCTAssertEqual(model.statusMessage, "Welcome")
        XCTAssertEqual(model.selectedTab, .home)
        XCTAssertTrue(model.generatedImages.isEmpty)
        XCTAssertTrue(model.capturedPhotos.isEmpty)
        XCTAssertTrue(model.savedPaintings.isEmpty)
        XCTAssertTrue(model.linkedMemories.isEmpty)
    }
}
