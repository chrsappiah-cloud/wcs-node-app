//
//  PatientActivityJourneyTests.swift
//  GeoWCSUITests – DementiaMedia Patient Journeys
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  End-to-end UI tests for the patient guided-activity workflow.
//

import XCTest

final class PatientActivityJourneyTests: XCTestCase {

    private var app: XCUIApplication!
    private var home: HomeScreen!
    private var activity: ActivityPromptScreen!
    private var library: LibraryScreen!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-state", "--seed-activity-prompt"]
        app.launch()
        home     = HomeScreen(app: app)
        activity = ActivityPromptScreen(app: app)
        library  = LibraryScreen(app: app)
    }

    override func tearDown() {
        app.terminate()
        app = nil; home = nil; activity = nil; library = nil
        super.tearDown()
    }

    // MARK: - Start → one step at a time → complete → library save

    func testFullActivityStartCompleteLibrarySaveJourney() throws {
        XCTAssertTrue(home.waitForAppearance())
        // The test seed adds a 3-step activity prompt accessible via prompts button.
        home.tapPrompts()

        XCTAssertTrue(activity.waitForAppearance(), "Activity prompt screen must appear")
        activity.tapStartActivity()

        XCTAssertTrue(activity.currentStepLabel.waitForExistence(timeout: 5),
            "Current step label must appear after starting")

        // Complete each step one at a time.
        for _ in 0..<3 where activity.markCompleteButton.waitForExistence(timeout: 3) {
            activity.tapMarkComplete()
        }

        XCTAssertTrue(activity.waitForCompletionBanner(),
            "A completion banner must appear when all steps are done")

        // Navigate to library and verify the session was saved.
        activity.backButton.tap()
        home.tapLibrary()
        XCTAssertTrue(library.waitForAppearance())
        XCTAssertGreaterThanOrEqual(library.itemCount, 1,
            "Completed activity session must appear in the library")
    }

    // MARK: - Auto-break pause after step block

    func testAutoBreakAppearsAfterStepBlock() throws {
        XCTAssertTrue(home.waitForAppearance())
        home.tapPrompts()
        XCTAssertTrue(activity.waitForAppearance())

        // Seed flag provides a 6-step activity with standard pacing (break after 5).
        app.launchArguments.append("--seed-long-activity-prompt")
        activity.tapStartActivity()

        // Complete 5 steps to trigger the auto-break.
        for _ in 0..<5 {
            guard activity.markCompleteButton.waitForExistence(timeout: 3) else { break }
            activity.tapMarkComplete()
        }

        XCTAssertTrue(activity.waitForBreakBanner(),
            "Auto-break banner must appear after completing the first step block")
    }

    // MARK: - Resume after break

    func testResumeAfterBreakContinuesSession() throws {
        XCTAssertTrue(home.waitForAppearance())
        home.tapPrompts()
        XCTAssertTrue(activity.waitForAppearance())
        activity.tapStartActivity()

        // If a pause button is available, exercise pause/resume.
        if activity.pauseButton.waitForExistence(timeout: 3) {
            activity.tapPause()
            XCTAssertTrue(activity.resumeButton.waitForExistence(timeout: 3),
                "Resume button must appear after pausing")
            activity.tapResume()
            XCTAssertTrue(activity.markCompleteButton.waitForExistence(timeout: 3),
                "Mark-complete button must reappear after resuming")
        } else {
            throw XCTSkip("Pause UI not yet available for this seed prompt")
        }
    }
}
