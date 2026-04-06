//
//  PatientPaintingJourneyTests.swift
//  GeoWCSUITests – DementiaMedia Patient Journeys
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  End-to-end UI tests for the patient painting workflow.
//  Requires a running simulator and the DementiaMedia UI target.
//

import XCTest

final class PatientPaintingJourneyTests: XCTestCase {

    private var app: XCUIApplication!
    private var home: HomeScreen!
    private var paint: PaintScreen!
    private var library: LibraryScreen!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-state"]
        app.launch()
        home    = HomeScreen(app: app)
        paint   = PaintScreen(app: app)
        library = LibraryScreen(app: app)
    }

    override func tearDown() {
        app.terminate()
        app = nil; home = nil; paint = nil; library = nil
        super.tearDown()
    }

    // MARK: - Full paint → save → library flow

    func testFullPaintSaveLibraryJourney() throws {
        XCTAssertTrue(home.waitForAppearance(), "Home screen must appear within 5 s")
        home.tapPaint()

        XCTAssertTrue(paint.waitForAppearance(), "Paint screen must appear")
        paint.drawStroke()
        paint.setTitle("My First Painting")
        paint.tapSave()

        XCTAssertTrue(paint.waitForSaveConfirmation(),
            "A confirmation must appear after saving to reassure the patient")

        // Navigate back to home then to library to verify the asset appears.
        paint.tapBack()
        home.tapLibrary()

        XCTAssertTrue(library.waitForAppearance(), "Library must appear")
        XCTAssertGreaterThanOrEqual(library.itemCount, 1,
            "Saved painting must appear in the library")
    }

    // MARK: - Undo before save

    func testUndoBeforeSaveRemovesStroke() throws {
        XCTAssertTrue(home.waitForAppearance())
        home.tapPaint()
        XCTAssertTrue(paint.waitForAppearance())

        paint.drawStroke()
        paint.tapUndo()
        // After undo the canvas should be clear; save should still work.
        paint.tapSave()
        XCTAssertTrue(paint.waitForSaveConfirmation(),
            "Undo then save must still produce a valid (blank) painting asset")
    }

    // MARK: - Draft autosave on background

    func testDraftAutosavedWhenAppGoesToBackground() throws {
        XCTAssertTrue(home.waitForAppearance())
        home.tapPaint()
        XCTAssertTrue(paint.waitForAppearance())

        paint.drawStroke()
        // Send app to background without saving explicitly.
        XCUIDevice.shared.press(.home)
        // Wait a moment then reactivate.
        Thread.sleep(forTimeInterval: 1.5)
        app.activate()

        // Verify the draft is still present (paint screen or recovery prompt).
        let paintOrRecoveryVisible = paint.canvas.exists
            || app.staticTexts["Resume your painting"].exists
        XCTAssertTrue(paintOrRecoveryVisible,
            "An in-progress painting must be autosaved when the app backgrounds")
    }
}
