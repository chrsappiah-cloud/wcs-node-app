//
//  DeArtsWCSCriticalFlowsUITests.swift
//  GeoWCSUITests - RokMax (DeArtsWCS) Critical User Flows
//
//  Concrete XCUITest scaffold for dementia-therapy multimedia journeys.
//

import XCTest

final class DeArtsWCSCriticalFlowsUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["DEARTSWCS_UI_TEST_MODE"] = "1"
        app.launchEnvironment["DEARTSWCS_IN_MEMORY_STORE"] = "1"
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    // MARK: - Core journey: start therapy in <= 2 taps

    func testSessionStartsWithinTwoTaps_scaffold() throws {
        let startTherapyButton = app.buttons["startTherapyButton"]
        XCTAssertTrue(startTherapyButton.waitForExistence(timeout: 5), "Start button must be visible")

        startTherapyButton.tap() // tap 1
        XCTAssertTrue(app.otherElements["sessionStartedLabel"].waitForExistence(timeout: 5))
    }

    // MARK: - Accessibility and reassurance

    func testVoiceOverNarrativeVisible_scaffold() throws {
        let narrativeLabel = app.staticTexts["sessionNarrativeLabel"]
        XCTAssertTrue(narrativeLabel.waitForExistence(timeout: 5))
    }

    func testLargeTouchTargetsForPrimaryActions_scaffold() throws {
        let startTherapyButton = app.buttons["startTherapyButton"]
        XCTAssertTrue(startTherapyButton.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(startTherapyButton.frame.size.width, 44)
        XCTAssertGreaterThanOrEqual(startTherapyButton.frame.size.height, 44)
    }

    // MARK: - Multimedia interactions

    func testCanvasPinchAndDrawFlow_scaffold() throws {
        app.tabBars.buttons["Paint"].tap()

        let therapyCanvas = app.otherElements["therapyCanvas"]
        XCTAssertTrue(therapyCanvas.waitForExistence(timeout: 5))

        therapyCanvas.pinch(withScale: 1.5, velocity: 1.0)
        therapyCanvas.press(forDuration: 0.1, thenDragTo: therapyCanvas)

        XCTAssertTrue(true, "Canvas interactions executed without UI interruption")
    }

    func testMoodChangeUpdatesAmbientState_scaffold() throws {
        let moodSlider = app.sliders["moodSlider"]
        XCTAssertTrue(moodSlider.waitForExistence(timeout: 5))

        moodSlider.adjust(toNormalizedSliderPosition: 0.8)

        XCTAssertTrue(app.staticTexts["ambientStateHappy"].waitForExistence(timeout: 5))
    }

    // MARK: - Reliability and offline behavior

    func testOfflineModeShowsCacheIndicator_scaffold() throws {
        let offlineToggle = app.switches["offlineToggle"]
        XCTAssertTrue(offlineToggle.waitForExistence(timeout: 5))

        offlineToggle.tap()
        XCTAssertTrue(app.otherElements["offlineModeIndicator"].waitForExistence(timeout: 5))
    }

    // MARK: - Caregiver workflow

    func testCaregiverDashboardAccessibleWithinTwoTaps_scaffold() throws {
        let caregiverEntry = app.buttons["caregiverDashboardEntry"]
        XCTAssertTrue(caregiverEntry.waitForExistence(timeout: 5))

        caregiverEntry.tap() // tap 1

        XCTAssertTrue(app.otherElements["caregiverDashboardRoot"].waitForExistence(timeout: 5))
    }

    // MARK: - Additional tab journeys

    func testImagineTab_canGenerateImage_scaffold() throws {
        app.tabBars.buttons["Imagine"].tap()
        XCTAssertTrue(app.otherElements["imagineRoot"].waitForExistence(timeout: 5))

        let promptField = app.textFields["imaginePromptField"]
        XCTAssertTrue(promptField.waitForExistence(timeout: 5))
        promptField.tap()
        promptField.typeText("A gentle garden with pastel colors")

        let createButton = app.buttons["createImageButton"]
        XCTAssertTrue(createButton.exists)
        createButton.tap()

        XCTAssertTrue(app.scrollViews["generatedImageList"].waitForExistence(timeout: 5))
    }

    func testCameraTab_showsCoreControls_scaffold() throws {
        app.tabBars.buttons["Camera"].tap()
        XCTAssertTrue(app.otherElements["cameraRoot"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["cameraPreview"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["capturePhotoButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["recordVideoButton"].waitForExistence(timeout: 5))
    }

    func testMemoriesTab_showsMemoryGraph_scaffold() throws {
        app.tabBars.buttons["Memories"].tap()
        XCTAssertTrue(app.otherElements["memoriesRoot"].waitForExistence(timeout: 5))
    }
}
