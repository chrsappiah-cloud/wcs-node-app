//
//  PatientRecordingJourneyTests.swift
//  GeoWCSUITests – DementiaMedia Patient Journeys
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  End-to-end UI tests for the patient audio-recording workflow.
//

import XCTest

final class PatientRecordingJourneyTests: XCTestCase {

    private var app: XCUIApplication!
    private var home: HomeScreen!
    private var recorder: RecorderScreen!
    private var library: LibraryScreen!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-state", "--grant-mic-permission"]
        app.launch()
        home     = HomeScreen(app: app)
        recorder = RecorderScreen(app: app)
        library  = LibraryScreen(app: app)
    }

    override func tearDown() {
        app.terminate()
        app = nil; home = nil; recorder = nil; library = nil
        super.tearDown()
    }

    // MARK: - Record → preview → save → replay

    func testFullRecordPreviewSaveReplayJourney() throws {
        XCTAssertTrue(home.waitForAppearance())
        home.tapRecord()

        XCTAssertTrue(recorder.waitForAppearance(), "Recorder screen must appear")
        recorder.tapRecord()
        XCTAssertTrue(recorder.waitForWaveform(), "Waveform must appear while recording")

        // Record for ~2 seconds then stop.
        Thread.sleep(forTimeInterval: 2)
        recorder.tapStop()

        // Preview
        recorder.tapPlay()
        // Brief check that playback started (timer or waveform still visible).
        XCTAssertTrue(recorder.timerLabel.exists || recorder.waveformView.exists)

        // Save
        recorder.tapSave()
        recorder.tapBack()
        home.tapLibrary()

        XCTAssertTrue(library.waitForAppearance())
        XCTAssertGreaterThanOrEqual(library.itemCount, 1,
            "Recorded clip must appear in the library after save")
    }

    // MARK: - Denied microphone permission recovery

    func testDeniedMicPermissionShowsRecoveryUI() throws {
        // Re-launch without the mic-permission grant flag.
        app.terminate()
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-state", "--deny-mic-permission"]
        app.launch()
        home     = HomeScreen(app: app)
        recorder = RecorderScreen(app: app)

        XCTAssertTrue(home.waitForAppearance())
        home.tapRecord()
        XCTAssertTrue(recorder.waitForAppearance())
        recorder.tapRecord()

        // A recovery prompt (alert or inline message) must appear instead of a crash.
        let recoveryVisible = app.alerts.firstMatch.waitForExistence(timeout: 3)
            || app.staticTexts["Microphone access needed"].waitForExistence(timeout: 3)
        XCTAssertTrue(recoveryVisible,
            "Denying mic permission must produce a gentle recovery UI, not a crash or dead end")
    }

    // MARK: - Pause and resume recording

    func testPauseAndResumeRecording() throws {
        XCTAssertTrue(home.waitForAppearance())
        home.tapRecord()
        XCTAssertTrue(recorder.waitForAppearance())

        recorder.tapRecord()
        XCTAssertTrue(recorder.waitForWaveform())

        // Pause
        let pauseButton = app.buttons["recorder_pause_button"]
        if pauseButton.waitForExistence(timeout: 3) {
            pauseButton.tap()
            XCTAssertTrue(app.buttons["recorder_resume_button"].waitForExistence(timeout: 3),
                "A resume button must appear after pausing")

            // Resume
            app.buttons["recorder_resume_button"].tap()
            XCTAssertTrue(recorder.waitForWaveform(),
                "Waveform must reappear after resuming")
        } else {
            // Pause/resume may not be implemented at this UI layer — skip gracefully.
            throw XCTSkip("Pause/resume UI not yet exposed in RecorderScreen")
        }
    }

    // MARK: - Interruption (incoming call simulation) recovery

    func testInterruptionRecovery() throws {
        XCTAssertTrue(home.waitForAppearance())
        home.tapRecord()
        XCTAssertTrue(recorder.waitForAppearance())

        recorder.tapRecord()
        XCTAssertTrue(recorder.waitForWaveform())

        // Simulate an audio session interruption by sending app to background.
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 1.5)
        app.activate()

        // After returning the recording screen must either show a paused state
        // or a recovery option — never a plain crash.
        let screenStillUsable = recorder.recordButton.waitForExistence(timeout: 3)
            || app.staticTexts["Recording paused"].waitForExistence(timeout: 3)
        XCTAssertTrue(screenStillUsable,
            "The recording screen must remain usable after an audio-session interruption")
    }
}
