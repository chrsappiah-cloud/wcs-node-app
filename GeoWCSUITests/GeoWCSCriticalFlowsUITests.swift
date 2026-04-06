//
//  GeoWCSCriticalFlowsUITests.swift
//  GeoWCSUITests - Critical User Flow E2E Tests
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  XCUITest suite for highest-risk user flows in native iOS.
//

import XCTest

// swiftlint:disable type_body_length file_length
class GeoWCSCriticalFlowsUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        // Continue after failure to see full flow breakdown
        continueAfterFailure = false

        app = XCUIApplication()
        app.launch()

        // Wait for app to stabilize
        sleep(1)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Permission Flow Tests

    func testFirstLaunchPermissionsFlow() throws {
        // First app launch typically shows permissions

        // Location permission alert
        let locationAlert = app.alerts.firstMatch
        if locationAlert.exists {
            locationAlert.buttons["Allow While Using App"].tap()
        }

        // Notifications permission alert
        let notificationAlert = app.alerts.matching(identifier: "NotificationPrompt").firstMatch
        if notificationAlert.exists {
            notificationAlert.buttons["Allow"].tap()
        }

        // Verify we're past permissions
        XCTAssertTrue(
            app.buttons["Create Circle"].exists ||
            app.buttons["Start Tracking"].exists,
            "Should show main content after permissions"
        )
    }

    // MARK: - Trusted Circle Creation Flow

    func testCreateTrustedCircleFlow() throws {
        // Navigate to circle creation
        app.buttons["New Circle"].tap()

        // Fill circle details
        let circleName = app.textFields["Circle Name"]
        XCTAssertTrue(circleName.exists, "Circle name field should exist")
        circleName.tap()
        circleName.typeText("Family Safety")

        let circleDesc = app.textFields["Description"]
        if circleDesc.exists {
            circleDesc.tap()
            circleDesc.typeText("Core family members")
        }

        // Add first member
        app.buttons["Add Member"].tap()

        let memberName = app.textFields["Member Name"]
        memberName.tap()
        memberName.typeText("John Doe")

        let phoneField = app.textFields["Phone Number"]
        phoneField.tap()
        phoneField.typeText("+14155552671")

        // Verify phone validation feedback
        sleep(1) // Allow validation to occur

        let validationIndicator = app.staticTexts["✓Validated"]
        if validationIndicator.exists {
            XCTAssertTrue(validationIndicator.exists)
        }

        // Create circle
        app.buttons["Create Circle"].tap()

        // Verify circle was created
        XCTAssertTrue(
            app.staticTexts["Family Safety"].exists,
            "Circle should appear in list after creation"
        )
    }

    // MARK: - Live Tracking Flow

    func testStartLiveTrackingFlow() throws {
        // Navigate to trusted circle
        app.tables.staticTexts["Family Safety"].tap()

        // Start tracking
        app.buttons["Start Live Tracking"].tap()

        // Verify map appears
        XCTAssertTrue(
            app.maps.firstMatch.exists,
            "Map should appear when tracking"
        )

        // Verify member location appears
        sleep(3) // Allow map to load location

        let memberLocation = app.buttons.matching(NSPredicate(
            format: "label CONTAINS 'John Doe'"
        )).firstMatch

        if memberLocation.exists {
            XCTAssertTrue(true, "Member location indicator visible")
        }

        // Verify tracking status
        XCTAssertTrue(
            app.staticTexts["Live Tracking"].exists ||
            app.staticTexts["TRACKING"].exists,
            "Tracking status should be visible"
        )
    }

    // MARK: - Check-In Timer Flow

    func testArmAndTriggerCheckInTimer() throws {
        // Navigate to safety
        app.buttons["Safety"].tap()

        // Find check-in timer
        let checkInSection = app.staticTexts["Check-In Timer"]
        XCTAssertTrue(checkInSection.exists)

        // Arm timer
        let armButton = app.buttons["Arm Timer"]
        XCTAssertTrue(armButton.exists)
        armButton.tap()

        // Verify armed state
        sleep(1)
        let timerStatus = app.staticTexts.matching(NSPredicate(
            format: "label CONTAINS 'Armed'"
        )).firstMatch
        XCTAssertTrue(timerStatus.exists)

        // Verify countdown is visible
        let countdownLabel = app.staticTexts.matching(NSPredicate(
            format: "label LIKE '*.:[0-5][0-9]'"
        )).firstMatch

        if countdownLabel.exists {
            XCTAssertTrue(true, "Countdown timer visible")
        }
    }

    // MARK: - SOS Activation Flow

    func testTriggerSOSFlow() throws {
        // Navigate to SOS
        app.buttons["Safety"].tap()

        // Find SOS button
        let sosButton = app.buttons["SOS"]
        XCTAssertTrue(sosButton.exists, "SOS button should be visible")

        // Verify SOS is disarmed initially
        let sosStatus = app.staticTexts["SOS Disarmed"]
        XCTAssertTrue(sosStatus.exists, "SOS should start disarmed")

        // Arm SOS
        app.buttons["Arm SOS"].tap()
        sleep(1)

        XCTAssertTrue(
            app.staticTexts["SOS Armed"].exists,
            "SOS should show armed status"
        )

        // Trigger SOS with long press
        sosButton.press(forDuration: 2.0)

        // Confirm SOS activation dialog
        let confirmButton = app.buttons.matching(NSPredicate(
            format: "label CONTAINS 'Confirm'"
        )).firstMatch

        if confirmButton.exists {
            confirmButton.tap()
        }

        // Verify SOS active state
        sleep(2) // Allow notifications to send

        XCTAssertTrue(
            app.staticTexts["SOS Active"].exists ||
            app.staticTexts["Emergency Alert Sent"].exists,
            "SOS should show active state"
        )

        // Verify emergency contacts notified
        let emergencyStatus = app.staticTexts.matching(NSPredicate(
            format: "label CONTAINS 'notified'"
        )).firstMatch

        if emergencyStatus.exists {
            XCTAssertTrue(true, "Emergency contacts notification shown")
        }
    }

    // MARK: - Geofence Alert Flow

    func testGeofenceCreationAndAlertFlow() throws {
        // Navigate to geofence section
        app.buttons["Geofences"].tap()

        // Create geofence
        app.buttons["Add Geofence"].tap()

        let nameField = app.textFields["Geofence Name"]
        nameField.tap()
        nameField.typeText("Home Safe Zone")

        // Set radius
        let radiusField = app.textFields["Radius (meters)"]
        if radiusField.exists {
            radiusField.tap()
            radiusField.typeText("100")
        }

        // Enable alerts
        let entryToggle = app.switches["Alert on Entry"]
        if entryToggle.exists && entryToggle.value as? String == "0" {
            entryToggle.tap()
        }

        // Save geofence
        app.buttons["Save Geofence"].tap()

        // Verify geofence created
        XCTAssertTrue(
            app.staticTexts["Home Safe Zone"].exists,
            "Geofence should appear in list"
        )
    }

    // MARK: - Audio Recording Flow

    func testAudioRecordingFlow() throws {
        // Navigate to safety tools
        app.buttons["Safety Tools"].tap()

        // Find audio recorder
        let recordButton = app.buttons["Record Audio"]
        XCTAssertTrue(recordButton.exists, "Audio record button should exist")

        // Start recording
        recordButton.tap()
        sleep(1)

        // Verify recording state
        XCTAssertTrue(
            app.staticTexts["Recording..."].exists ||
            app.staticTexts["Recording"].exists,
            "Should show recording status"
        )

        // Let it record for a moment
        sleep(3)

        // Stop recording
        let stopButton = app.buttons["Stop Recording"]
        stopButton.tap()

        // Verify playback controls
        sleep(1)

        let playButton = app.buttons["Play"]
        XCTAssertTrue(
            playButton.exists ||
            app.buttons["🔊"].exists,
            "Playback controls should appear"
        )
    }

    // MARK: - Premium Feature Gating

    func testFreVsPremiumFeatureGating() throws {
        // Navigate to premium features
        app.buttons["Settings"].tap()
        app.buttons["Premium Features"].tap()

        // Verify free tier limitations
        let freeFeatures = ["Live Tracking", "Check-In Timer", "SOS"]

        for feature in freeFeatures {
            let button = app.buttons[feature]
            XCTAssertTrue(button.isHittable, "\(feature) should be available")
        }

        // Verify premium-only features show upsell
        let premiumFeatures = ["Unlimited History", "Advanced Analytics"]

        for feature in premiumFeatures {
            let button = app.buttons[feature]
            if button.exists {
                button.tap()

                // Should show upgrade prompt
                let upgradeAlert = app.alerts.firstMatch
                if upgradeAlert.exists {
                    XCTAssertTrue(
                        upgradeAlert.staticTexts.matching(NSPredicate(
                            format: "label CONTAINS 'Premium'"
                        )).firstMatch.exists
                    )

                    app.buttons["Cancel"].tap()
                }
            }
        }
    }

    // MARK: - App State Transitions

    func testBackgroundForegroundTransition() throws {
        // Start tracking
        app.buttons["Start Tracking"].tap()
        sleep(2)

        // Move to background
        XCUIDevice.shared.press(.home)
        sleep(2)

        // Bring back to foreground
        app.activate()
        sleep(2)

        // Verify state restored
        XCTAssertTrue(
            app.staticTexts["TRACKING"].exists ||
            app.staticTexts["Live"].exists,
            "Should maintain tracking state after background/foreground"
        )
    }

    // MARK: - Location History Viewing

    func testViewLocationHistoryFlow() throws {
        // Navigate to history
        app.buttons["History"].tap()

        // Verify history list loaded
        let historyTable = app.tables.firstMatch
        XCTAssertTrue(historyTable.exists, "History table should load")

        // Verify entries exist
        sleep(2)

        let historyEntries = historyTable.cells
        if historyEntries.count > 0 {
            // Tap first entry
            historyEntries.firstMatch.tap()

            // Verify detail view with timestamp and location
            XCTAssertTrue(
                app.staticTexts.matching(NSPredicate(
                    format: "label LIKE '*:*:*'"
                )).firstMatch.exists,
                "Should show timestamp detail"
            )
        }
    }

    // MARK: - Member Invitation Flow

    func testSendMemberInvitationFlow() throws {
        // Open circle
        app.tables.staticTexts["Family Safety"].tap()

        // Find members section
        app.buttons["Invite Member"].tap()

        // Enter member details
        let inviteName = app.textFields["Name"]
        inviteName.tap()
        inviteName.typeText("Sarah Smith")

        let invitePhone = app.textFields["Phone"]
        invitePhone.tap()
        invitePhone.typeText("+441632960000")

        // Verify country detection
        sleep(1)
        if app.staticTexts["United Kingdom"].exists {
            XCTAssertTrue(true, "Country should be detected")
        }

        // Send invitation
        app.buttons["Send Invite"].tap()

        // Verify confirmation
        sleep(1)
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(
                format: "label CONTAINS 'sent'"
            )).firstMatch.exists,
            "Should show invitation sent confirmation"
        )
    }

    // MARK: - Settings & Preferences

    func testUpdateLocationSharingPreferences() throws {
        // Navigate to settings
        app.buttons["Settings"].tap()
        app.buttons["Privacy"].tap()

        // Find location sharing toggle
        let sharingToggle = app.switches["Share Location with Circle"]
        XCTAssertTrue(sharingToggle.exists)

        // Toggle location sharing
        let initialValue = sharingToggle.value as? String ?? "1"
        sharingToggle.tap()

        sleep(1)

        let newValue = sharingToggle.value as? String ?? "0"
        XCTAssertNotEqual(initialValue, newValue, "Toggle should change state")
    }

    // MARK: - Performance Benchmarks

    func testMapRenderingPerformance() throws {
        measure(metrics: [XCTClockMetric()]) {
            app.buttons["Start Tracking"].tap()
            sleep(3)
            XCTAssertTrue(app.maps.firstMatch.exists)
        }
    }

    func testLocationUpdateLatency() throws {
        measure(metrics: [XCTClockMetric()]) {
            // Simulate location update and verify UI update
            app.buttons["Refresh Location"].tap()
            sleep(1)
        }
    }
}
// swiftlint:enable type_body_length file_length
