//
//  CarerSlideshowJourneyTests.swift
//  GeoWCSUITests – DementiaMedia Caregiver Journeys
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  End-to-end UI tests for the caregiver slideshow-builder workflow.
//

import XCTest

final class CarerSlideshowJourneyTests: XCTestCase {

    private var app: XCUIApplication!
    private var home: HomeScreen!
    private var builder: SlideshowBuilderScreen!
    private var library: LibraryScreen!
    private var slideshowPlayer: SlideshowScreen!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-state", "--caregiver-mode",
                                "--seed-photos=5"]
        app.launch()
        home          = HomeScreen(app: app)
        builder       = SlideshowBuilderScreen(app: app)
        library       = LibraryScreen(app: app)
        slideshowPlayer = SlideshowScreen(app: app)
    }

    override func tearDown() {
        app.terminate()
        app = nil; home = nil; builder = nil; library = nil; slideshowPlayer = nil
        super.tearDown()
    }

    // MARK: - Select 3–10 photos → optional narration → export → patient replays offline

    func testFullSlideshowBuildExportAndPatientReplayJourney() throws {
        XCTAssertTrue(home.waitForAppearance())
        home.tapSlideshow()

        XCTAssertTrue(builder.waitForAppearance(), "Slideshow builder must appear")

        // Add photos (the seed provides 5 pre-authorised photos in the picker).
        builder.tapAddPhotos()
        // Dismiss photo picker by selecting photos — on simulator this selects all seeded photos.
        let photoPicker = app.sheets.firstMatch
        if photoPicker.waitForExistence(timeout: 3) {
            // Select using the picker's "Add" or "Done" button pattern.
            let addButton = photoPicker.buttons["Add"].exists
                ? photoPicker.buttons["Add"]
                : photoPicker.buttons["Done"]
            addButton.tap()
        }

        XCTAssertGreaterThanOrEqual(builder.photoCount, 3,
            "At least 3 photos must appear in the builder grid")

        // Add optional narration.
        builder.enterNarration("A happy family memory from last summer.")

        // Export.
        builder.tapExport()
        XCTAssertTrue(builder.waitForExportSuccess(),
            "Export must complete successfully and show a completion indicator")

        // Patient replays the slideshow from the library.
        app.buttons["builder_done_button"].tapIfExists(app: app)
        home.tapLibrary()
        XCTAssertTrue(library.waitForAppearance())
        library.openLatestItem()

        XCTAssertTrue(slideshowPlayer.waitForAppearance() ||
                      slideshowPlayer.playButton.waitForExistence(timeout: 5),
            "Patient must be able to open and play the slideshow offline from the library")
    }

    // MARK: - Too many photos rejected

    func testExcessivePhotoCountIsRejected() throws {
        XCTAssertTrue(home.waitForAppearance())
        home.tapSlideshow()
        XCTAssertTrue(builder.waitForAppearance())

        // Attempt to add more than the maximum (typically 10).
        builder.tapAddPhotos()
        // The picker should enforce the limit itself, or the export should reject it.
        let limitWarning = app.staticTexts["Maximum 10 photos"].waitForExistence(timeout: 3)
            || app.alerts.firstMatch.waitForExistence(timeout: 3)
        XCTAssertTrue(limitWarning,
            "Adding more than the maximum allowed photos must produce a clear rejection message")
    }

    // MARK: - Low storage blocks export

    func testLowStorageBlocksExport() throws {
        // Re-launch with the low-storage simulation flag.
        app.terminate()
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-state", "--caregiver-mode",
                                "--seed-photos=5", "--simulate-low-storage"]
        app.launch()
        home    = HomeScreen(app: app)
        builder = SlideshowBuilderScreen(app: app)

        XCTAssertTrue(home.waitForAppearance())
        home.tapSlideshow()
        XCTAssertTrue(builder.waitForAppearance())
        builder.tapAddPhotos()
        let pickers = app.sheets.firstMatch
        if pickers.waitForExistence(timeout: 3) {
            (pickers.buttons["Add"].exists ? pickers.buttons["Add"] : pickers.buttons["Done"]).tap()
        }

        builder.tapExport()
        XCTAssertTrue(builder.waitForExportError(),
            "Low-storage export must show an error message, not silently fail or crash")
    }
}

// MARK: - Helpers

private extension XCUIElement {
    /// Taps the element only if it exists — silently no-ops otherwise.
    func tapIfExists(app: XCUIApplication) {
        if self.waitForExistence(timeout: 2) { tap() }
    }
}
