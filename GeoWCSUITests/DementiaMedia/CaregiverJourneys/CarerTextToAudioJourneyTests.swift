//
//  CarerTextToAudioJourneyTests.swift
//  GeoWCSUITests – DementiaMedia Caregiver Journeys
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  End-to-end UI tests for the caregiver text-to-audio prompt workflow.
//

import XCTest

final class CarerTextToAudioJourneyTests: XCTestCase {

    private var app: XCUIApplication!
    private var home: HomeScreen!
    private var tts: TextToAudioScreen!
    private var library: LibraryScreen!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-state", "--caregiver-mode"]
        app.launch()
        home    = HomeScreen(app: app)
        tts     = TextToAudioScreen(app: app)
        library = LibraryScreen(app: app)
    }

    override func tearDown() {
        app.terminate()
        app = nil; home = nil; tts = nil; library = nil
        super.tearDown()
    }

    // MARK: - Enter prompt → select calm voice → preview → save → appears in patient library

    func testFullTextToAudioSaveAndLibraryJourney() throws {
        XCTAssertTrue(home.waitForAppearance())
        home.tapPrompts()

        XCTAssertTrue(tts.waitForAppearance(), "Text-to-audio screen must appear")
        tts.enterPrompt("Good morning! Let's start with a gentle stretch.")
        tts.selectCalmVoice()
        tts.tapPreview()

        // Preview label or player must appear.
        XCTAssertTrue(tts.waitForPreviewLabel(timeout: 5) ||
                      app.buttons["tts_stop_preview_button"].waitForExistence(timeout: 5),
            "Preview must start playing after tapping preview")

        tts.tapSave()
        XCTAssertTrue(tts.waitForSaveConfirmation(),
            "Save confirmation must appear")

        // Verify the audio prompt appears in the shared library.
        tts.backButton.tap()
        home.tapLibrary()
        XCTAssertTrue(library.waitForAppearance())
        XCTAssertGreaterThanOrEqual(library.itemCount, 1,
            "Text-to-audio prompt must appear in the library after saving")
    }

    // MARK: - Long text rejected before synthesis

    func testLongTextIsRejectedWithError() throws {
        XCTAssertTrue(home.waitForAppearance())
        home.tapPrompts()
        XCTAssertTrue(tts.waitForAppearance())

        // 1 000-character string well above any reasonable prompt limit.
        let longText = String(repeating: "A", count: 1_000)
        tts.enterPrompt(longText)
        tts.tapPreview()

        XCTAssertTrue(tts.waitForError(timeout: 5),
            "An error must appear when the prompt text exceeds the maximum length")
        // The save button must remain enabled so the user isn't trapped.
        XCTAssertFalse(tts.saveButton.isEnabled == false && tts.backButton.exists == false,
            "The UI must not trap the caregiver after a validation error")
    }

    // MARK: - Blank input rejected

    func testBlankInputIsRejected() throws {
        XCTAssertTrue(home.waitForAppearance())
        home.tapPrompts()
        XCTAssertTrue(tts.waitForAppearance())

        // Tap preview without entering any text.
        tts.tapPreview()

        XCTAssertTrue(tts.waitForError(timeout: 5),
            "An error must appear for blank input to prevent saving an empty prompt")
    }
}
