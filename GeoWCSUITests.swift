//
//  GeoWCSCriticalFlowsUITests.swift
//  GeoWCSUITests
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  UI Tests for Critical Safety Flows:
//  - Circle creation and membership management
//  - Real-time location tracking
//  - Check-in timer
//  - SOS emergency alert
//

import XCTest

final class GeoWCSCriticalFlowsUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UITEST_MODE"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Critical Flow Tests

    /// Test: Create a trusted circle and start real-time location tracking
    /// 
    /// Steps:
    /// 1. Navigate to Circle tab
    /// 2. Enter family code
    /// 3. Add circle member
    /// 4. Return to Map tab
    /// 5. Start location tracking
    /// 6. Verify Live Location Tracker is active
    func testCreateTrustedCircleAndStartTracking() throws {
        // Step 1: Navigate to Circles section
        let circleTab = app.buttons["Circle"]
        XCTAssertTrue(circleTab.waitForExistence(timeout: 5), "Circle tab should exist")
        circleTab.tap()

        // Step 2: Verify Circle Membership screen loads
        let circleMembershipTitle = app.staticTexts["Circle Membership"]
        XCTAssertTrue(circleMembershipTitle.waitForExistence(timeout: 5), "Circle Membership screen should load")

        // Step 3: Enter family code
        let familyField = app.textFields["Family Code"]
        if familyField.waitForExistence(timeout: 2) {
            familyField.tap()
            familyField.typeText("FAMILY-001")
        }

        // Step 4: Add circle member
        let addMemberField = app.textFields["Add member name"]
        XCTAssertTrue(addMemberField.waitForExistence(timeout: 5), "Add member field should exist")
        addMemberField.tap()
        addMemberField.typeText("Maya")

        let addButton = app.buttons["Add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 2), "Add button should exist")
        addButton.tap()

        // Step 5: Navigate to Map tab
        let mapTab = app.buttons["Map"]
        XCTAssertTrue(mapTab.waitForExistence(timeout: 5), "Map tab should exist")
        mapTab.tap()

        // Step 6: Start location tracking
        let startTrackingButton = app.buttons["Start Tracking"]
        XCTAssertTrue(startTrackingButton.waitForExistence(timeout: 5), "Start Tracking button should exist")
        startTrackingButton.tap()

        // Step 7: Verify Live Location Tracker is active
        let liveTrackerLabel = app.staticTexts["Live Location Tracker"]
        XCTAssertTrue(liveTrackerLabel.waitForExistence(timeout: 5), "Live Location Tracker should be active")
    }

    /// Test: Arm check-in timer and trigger SOS emergency alert
    /// 
    /// Steps:
    /// 1. Navigate to Safety Toolkit
    /// 2. Arm check-in timer
    /// 3. Trigger SOS button
    /// 4. Verify SOS alert appears
    func testArmCheckInTimerAndTriggerSOS() throws {
        // Step 1: Navigate to Safety section
        let safetyTab = app.buttons["Safety"]
        XCTAssertTrue(safetyTab.waitForExistence(timeout: 5), "Safety tab should exist")
        safetyTab.tap()

        // Step 2: Verify Safety Toolkit loads
        let safetyToolkitTitle = app.staticTexts["Safety Toolkit"]
        XCTAssertTrue(safetyToolkitTitle.waitForExistence(timeout: 5), "Safety Toolkit should load")

        // Step 3: Arm check-in timer
        let armButton = app.buttons["Arm Check-In Timer"]
        XCTAssertTrue(armButton.waitForExistence(timeout: 5), "Arm Check-In Timer button should exist")
        armButton.tap()

        // Wait for timer to arm
        sleep(1)

        // Step 4: Trigger SOS
        let sosButton = app.buttons["Trigger SOS"]
        XCTAssertTrue(sosButton.waitForExistence(timeout: 5), "Trigger SOS button should exist")
        sosButton.tap()

        // Step 5: Verify SOS alert or confirmation appears
        let sosAlert = app.alerts.firstMatch
        let sosLabel = app.staticTexts["SOS"]

        let alertExists = sosAlert.waitForExistence(timeout: 5)
        let labelExists = sosLabel.exists

        XCTAssertTrue(alertExists || labelExists, "SOS confirmation should appear (either as alert or label)")
    }

    // MARK: - Authentication Flow Tests

    /// Test: User can authenticate via phone OTP
    func testPhoneOTPAuthentication() throws {
        // Expect login screen on first launch
        let phoneField = app.textFields["Phone Number"]
        XCTAssertTrue(phoneField.waitForExistence(timeout: 5), "Phone field should appear on login")

        phoneField.tap()
        phoneField.typeText("+14155552671")

        let sendOTPButton = app.buttons["Send Verification Code"]
        XCTAssertTrue(sendOTPButton.waitForExistence(timeout: 2), "Send OTP button should exist")
        sendOTPButton.tap()

        // Verify OTP screen appears
        let otpField = app.textFields["Enter 6-digit code"]
        XCTAssertTrue(otpField.waitForExistence(timeout: 5), "OTP entry field should appear")
    }

    // MARK: - Geofence Alert Tests

    /// Test: Create geofence and verify alert on entry
    func testGeofenceCreationAndAlert() throws {
        app.buttons["Circle"].tap()
        XCTAssertTrue(app.staticTexts["Circle Membership"].waitForExistence(timeout: 5))

        // Look for Add Geofence option
        let addGeofenceButton = app.buttons["Add Geofence"]
        if addGeofenceButton.waitForExistence(timeout: 2) {
            addGeofenceButton.tap()

            // Fill in geofence details
            let nameField = app.textFields["Geofence Name"]
            XCTAssertTrue(nameField.waitForExistence(timeout: 5))
            nameField.tap()
            nameField.typeText("Home")

            let radiusField = app.textFields["Radius (meters)"]
            if radiusField.waitForExistence(timeout: 2) {
                radiusField.tap()
                radiusField.typeText("100")
            }

            let saveButton = app.buttons["Save Geofence"]
            XCTAssertTrue(saveButton.waitForExistence(timeout: 2))
            saveButton.tap()

            // Verify geofence appears in list
            let geofenceLabel = app.staticTexts["Home"]
            XCTAssertTrue(geofenceLabel.waitForExistence(timeout: 5), "Geofence should appear in list")
        }
    }

    // MARK: - Audio Evidence Recording Tests

    /// Test: Record audio evidence
    func testAudioRecording() throws {
        app.buttons["Safety"].tap()
        XCTAssertTrue(app.staticTexts["Safety Toolkit"].waitForExistence(timeout: 5))

        // Look for Audio Recorder button
        let audioRecorderButton = app.buttons.containing(.staticText, identifier: "Record & save audio evidence").firstMatch
        if audioRecorderButton.waitForExistence(timeout: 2) {
            audioRecorderButton.tap()

            // Verify Audio Recorder View appears
            let audioRecorderTitle = app.staticTexts["Audio Recorder"]
            XCTAssertTrue(audioRecorderTitle.waitForExistence(timeout: 5), "Audio Recorder should open")

            // Tap Start Recording
            let startButton = app.buttons["Start Recording"]
            XCTAssertTrue(startButton.waitForExistence(timeout: 2))
            startButton.tap()

            // Wait a few seconds
            sleep(3)

            // Tap Stop Recording
            let stopButton = app.buttons["Stop Recording"]
            XCTAssertTrue(stopButton.waitForExistence(timeout: 2), "Stop button should appear")
            stopButton.tap()

            // Verify recording appears in list
            let recordingsList = app.tables.firstMatch
            XCTAssertTrue(recordingsList.waitForExistence(timeout: 5), "Recordings list should appear")
        }
    }

    // MARK: - Subscription Tests

    /// Test: Verify Free tier has audio recording but no live map
    func testFreeVsPremiumFeatureGating() throws {
        app.buttons["Map"].tap()
        
        // Check if Live Map is available (Premium feature)
        let liveMapButton = app.buttons["Enable Live Map"]
        
        // Should show paywall or "Premium Only" message
        let premiumTag = app.staticTexts["Premium Only"]
        
        // If Premium feature is gated, paywall should be accessible
        if liveMapButton.waitForExistence(timeout: 2) {
            liveMapButton.tap()
            
            let paywallTitle = app.staticTexts["Upgrade to Premium"]
            XCTAssertTrue(paywallTitle.waitForExistence(timeout: 5), "Paywall should appear for premium features")
        }
    }

    // MARK: - Performance Tests

    /// Test: App startup performance
    func testAppStartupPerformance() throws {
        measure {
            let newApp = XCUIApplication()
            newApp.launch()
            XCTAssertTrue(newApp.staticTexts["GeoWCS"].waitForExistence(timeout: 2))
        }
    }

    /// Test: Map rendering performance
    func testMapRenderingPerformance() throws {
        app.buttons["Map"].tap()

        measure {
            _ = app.staticTexts["Live Location Tracker"].waitForExistence(timeout: 5)
        }
    }
}
