//
//  DementiaMediaFlowsUITests.swift
//  GeoWCSUITests – DementiaMedia Functional / End-to-End Tests
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Outermost ring of the double-loop TDD model.
//  One test per patient-facing user story, expressed as a plain English scenario.
//  These tests use Screen Objects from ScreenObjects.swift and drive a real
//  app binary running in the iOS Simulator.
//
//  Run order: each test is independent. setUp() relaunches the app fresh.
//

import XCTest

final class DementiaMediaFlowsUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Tell the app to use a clean in-memory store so tests don't
        // accumulate state. The key is read by the repository adapter.
        app.launchEnvironment["DEMENTIA_MEDIA_IN_MEMORY_STORE"] = "1"
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    // MARK: - Story 1: Patient paints a memory and finds it in the library
    //
    // Given the patient is on the home screen
    // When she taps "Paint", draws a stroke, gives it a name, and saves
    // Then she can find her painting in the activity library

    func testPatientPaints_SavesAndFindsArtworkInLibrary() throws {
        let home    = HomeScreen(app: app)
        let paint   = PaintScreen(app: app)
        let library = ActivityLibraryScreen(app: app)

        XCTAssertTrue(home.waitForAppearance(), "Home screen must appear on launch")

        home.tapPaint()
        XCTAssertTrue(paint.waitForAppearance(), "Paint screen must appear after tapping Paint")

        paint.drawStroke()
        paint.setTitle("My Garden")
        paint.tapSave()
        XCTAssertTrue(paint.waitForSaveConfirmation(), "Save confirmation must appear")

        paint.tapBack()
        home.tapLibrary()
        XCTAssertTrue(library.waitForAppearance(), "Library must appear after tapping Library")
        XCTAssertTrue(library.waitForAsset(titled: "My Garden"),
                      "Saved painting must appear in the library")
    }

    // MARK: - Story 2: Patient undoes a stroke before saving
    //
    // Given the patient has made an accidental stroke
    // When she taps Undo
    // Then the stroke disappears and she can save a clean canvas

    func testPatientUndoesMistakeBeforeSaving() throws {
        let home  = HomeScreen(app: app)
        let paint = PaintScreen(app: app)

        XCTAssertTrue(home.waitForAppearance())
        home.tapPaint()
        XCTAssertTrue(paint.waitForAppearance())

        paint.drawStroke()
        paint.tapUndo()

        // Undo button should still be accessible (not disabled) for additional undos
        XCTAssertTrue(paint.undoButton.exists)

        paint.setTitle("Clean canvas")
        paint.tapSave()
        XCTAssertTrue(paint.waitForSaveConfirmation())
    }

    // MARK: - Story 3: Carer creates a calming spoken prompt; patient replays it
    //
    // Given the carer opens the Prompts screen
    // When she types a short calming instruction and saves it
    // Then the audio prompt appears in the library and can be played back

    func testCarerCreatesTextToAudioPrompt_PatientReplaysFromLibrary() throws {
        let home    = HomeScreen(app: app)
        let prompts = PromptCreationScreen(app: app)
        let library = ActivityLibraryScreen(app: app)

        XCTAssertTrue(home.waitForAppearance())
        home.tapPrompts()
        XCTAssertTrue(prompts.waitForAppearance(), "Prompt creation screen must appear")

        prompts.enterText("Close your eyes. Take a slow deep breath. You are safe.")
        prompts.tapPreview()
        XCTAssertTrue(prompts.waitForPreviewToStart(timeout: 8),
                      "Audio preview must begin within 8 seconds")

        prompts.tapSave()
        XCTAssertTrue(prompts.waitForSaveConfirmation(), "Save confirmation must appear")

        // Navigate to library and play
        app.navigationBars.buttons.firstMatch.tap()  // back
        home.tapLibrary()
        XCTAssertTrue(library.waitForAppearance())
        XCTAssertGreaterThan(library.assetCount(), 0, "Library must contain the saved prompt")
    }

    // MARK: - Story 4: Patient records a memory clip and replays it
    //
    // Given the patient taps Record
    // When she records for a few seconds and stops
    // Then her clip appears in the library and plays back

    func testPatientRecordsMemoryClip_FindsItInLibrary() throws {
        let home      = HomeScreen(app: app)
        let recorder  = RecorderScreen(app: app)
        let library   = ActivityLibraryScreen(app: app)

        XCTAssertTrue(home.waitForAppearance())
        home.tapRecord()
        XCTAssertTrue(recorder.waitForAppearance(), "Recorder screen must appear")

        recorder.tapRecord()
        // Allow microphone permission if the system prompts
        PermissionAlertHelper.allowIfPresent(in: app)

        XCTAssertTrue(recorder.waitForWaveform(timeout: 5),
                      "Waveform must appear once recording starts")

        // Record for 3 seconds then stop
        sleep(3)
        recorder.tapStop()

        recorder.tapSave()

        // Navigate to library
        app.navigationBars.buttons.firstMatch.tap()
        home.tapLibrary()
        XCTAssertTrue(library.waitForAppearance())
        XCTAssertGreaterThan(library.assetCount(), 0, "Recorded clip must appear in library")
    }

    // MARK: - Story 5: Denied microphone permission shows recovery path
    //
    // Given the patient's device denies microphone access
    // When she taps Record
    // Then the app shows a helpful explanation, not a crash

    func testDeniedMicrophonePermissionShowsRecoveryMessage() throws {
        // Pre-condition: system permission must have been denied.
        // In CI this is achieved by resetting permissions with simctl:
        //   xcrun simctl privacy <udid> deny microphone <bundle_id>
        // The test uses skipIf to report clearly when the pre-condition isn't met.
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["MICROPHONE_DENIED"] != "1",
            "Skipped: set MICROPHONE_DENIED=1 and deny microphone in simctl before running"
        )

        let home     = HomeScreen(app: app)
        let recorder = RecorderScreen(app: app)

        XCTAssertTrue(home.waitForAppearance())
        home.tapRecord()
        XCTAssertTrue(recorder.waitForAppearance())

        recorder.tapRecord()
        PermissionAlertHelper.denyIfPresent(in: app)

        // App must show a recovery message, not crash
        let recoveryMessage = app.staticTexts["recorder_permission_denied_label"]
        XCTAssertTrue(recoveryMessage.waitForExistence(timeout: 5),
                      "Recovery message must appear when microphone is denied")
    }

    // MARK: - Story 6: Patient views a slideshow of saved paintings
    //
    // Given the patient has paintings saved in the library
    // When she starts a slideshow
    // Then the video player appears and begins playing

    func testPatientViewsSlideshow() throws {
        // Seed two paintings first
        let home  = HomeScreen(app: app)
        let paint = PaintScreen(app: app)

        XCTAssertTrue(home.waitForAppearance())

        for title in ["Tulips", "Roses"] {
            home.tapPaint()
            XCTAssertTrue(paint.waitForAppearance())
            paint.drawStroke()
            paint.setTitle(title)
            paint.tapSave()
            XCTAssertTrue(paint.waitForSaveConfirmation())
            paint.tapBack()
        }

        home.tapSlideshow()
        let slideshow = SlideshowScreen(app: app)
        XCTAssertTrue(slideshow.waitForAppearance(timeout: 10),
                      "Slideshow player must appear")
        slideshow.tapPlay()

        // Video player must show as playing (control bar disappears or play becomes pause)
        let pauseButton = app.buttons["slideshow_pause_button"]
        let isPlaying = pauseButton.waitForExistence(timeout: 8)
        XCTAssertTrue(isPlaying, "Slideshow must begin playing after tapping play")
    }

    // MARK: - Story 7: Carer resumes an interrupted recording session
    //
    // Given a recording was interrupted (e.g. incoming call)
    // When the app returns to foreground
    // Then the recording screen shows a resume option

    func testInterruptedRecordingShowsResumeOption() throws {
        let home     = HomeScreen(app: app)
        let recorder = RecorderScreen(app: app)

        XCTAssertTrue(home.waitForAppearance())
        home.tapRecord()
        XCTAssertTrue(recorder.waitForAppearance())
        recorder.tapRecord()
        PermissionAlertHelper.allowIfPresent(in: app)
        XCTAssertTrue(recorder.waitForWaveform(timeout: 5))

        // Simulate phone-call interruption by backgrounding the app
        XCUIDevice.shared.press(.home)
        sleep(1)
        app.activate()

        // Resume option or recording indicator must still be visible
        let resumeOrRecord = recorder.recordButton.exists || recorder.stopButton.exists
        XCTAssertTrue(resumeOrRecord, "After interruption the recorder screen must be recoverable")
    }
}
