//
//  SafetyEngineTests.swift
//  GeoWCSTests - Safety Logic Unit Tests
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Pure logic tests for safety rule evaluation and SOS state transitions.
//

import XCTest

class SafetyEngineTests: XCTestCase {
    
    var sut: SafetyEngine!
    
    override func setUp() {
        super.setUp()
        sut = SafetyEngine()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - SOS State Transitions
    
    func testInitialSOSStateIsDisarmed() {
        XCTAssertEqual(sut.sosState, .disarmed)
        XCTAssertFalse(sut.isSOSActive)
    }
    
    func testArmSOSChangesState() {
        sut.armSOS()
        XCTAssertEqual(sut.sosState, .armed)
        XCTAssertTrue(sut.isSOSActive)
    }
    
    func testDisarmSOSChangesState() {
        sut.armSOS()
        XCTAssertEqual(sut.sosState, .armed)
        
        sut.disarmSOS()
        XCTAssertEqual(sut.sosState, .disarmed)
        XCTAssertFalse(sut.isSOSActive)
    }
    
    func testSOSActivationRemainsActiveUntilDisarmed() {
        sut.armSOS()
        sut.triggerSOS()
        
        XCTAssertEqual(sut.sosState, .active)
        XCTAssertTrue(sut.isSOSActive)
    }
    
    func testDisarmSOSFromAnyState() {
        // From armed
        sut.armSOS()
        sut.disarmSOS()
        XCTAssertEqual(sut.sosState, .disarmed)
        
        // From active
        sut.armSOS()
        sut.triggerSOS()
        sut.disarmSOS()
        XCTAssertEqual(sut.sosState, .disarmed)
    }
    
    func testSOSCannotBeTriggerredUnlessArmed() {
        XCTAssertThrowsError(try sut.triggerSOS()) { error in
            XCTAssertEqual(error as? SafetyEngineError, .sosNotArmed)
        }
    }
    
    func testSOSRequiresArmedState() {
        sut.armSOS()
        XCTAssertNoThrow(try sut.triggerSOS())
    }
    
    // MARK: - Geofence Evaluation
    
    func testGeofenceAlertOnEntryWhenInsideZone() {
        let geofence = Geofence(
            id: "home",
            latitude: 37.7749,
            longitude: -122.4194,
            radiusMeters: 100,
            alertOnEntry: true,
            alertOnExit: false
        )
        
        let userLocation = LocationCoordinate(lat: 37.7750, lon: -122.4195)
        
        let rule = sut.evaluateGeofence(geofence, forLocation: userLocation)
        XCTAssertTrue(rule.shouldAlert)
        XCTAssertEqual(rule.alertType, .entry)
    }
    
    func testGeofenceAlertOnExitWhenLeavingZone() {
        let geofence = Geofence(
            id: "home",
            latitude: 37.7749,
            longitude: -122.4194,
            radiusMeters: 100,
            alertOnEntry: false,
            alertOnExit: true
        )
        
        let userLocation = LocationCoordinate(lat: 37.7800, lon: -122.4200) // Outside
        
        let rule = sut.evaluateGeofence(geofence, forLocation: userLocation)
        XCTAssertTrue(rule.shouldAlert)
        XCTAssertEqual(rule.alertType, .exit)
    }
    
    func testNoAlertWhenOutsideGeofenceAndAlertOnExitDisabled() {
        let geofence = Geofence(
            id: "work",
            latitude: 37.3382,
            longitude: -121.8863,
            radiusMeters: 100,
            alertOnEntry: false,
            alertOnExit: false
        )
        
        let userLocation = LocationCoordinate(lat: 37.4000, lon: -121.9000)
        
        let rule = sut.evaluateGeofence(geofence, forLocation: userLocation)
        XCTAssertFalse(rule.shouldAlert)
    }
    
    func testGeofenceDistanceCalculation() {
        let geofence = Geofence(
            id: "test",
            latitude: 37.7749,
            longitude: -122.4194,
            radiusMeters: 100,
            alertOnEntry: true,
            alertOnExit: true
        )
        
        // User exactly at geofence center
        let center = LocationCoordinate(lat: 37.7749, lon: -122.4194)
        let distance = sut.calculateDistance(from: center, to: geofence)
        XCTAssertLessThan(distance, 1.0) // Less than 1 meter
    }
    
    // MARK: - Check-In Timer Logic
    
    func testCheckInTimerInitialization() {
        let timer = CheckInTimer(intervalSeconds: 3600, enabled: true)
        XCTAssertTrue(timer.isActive)
        XCTAssertEqual(timer.remainingSeconds, 3600)
        XCTAssertFalse(timer.hasMissedCheckIn)
    }
    
    func testCheckInTimerMissedWhenExpired() {
        let timer = CheckInTimer(intervalSeconds: 1, enabled: true)
        
        // Simulate passage of time
        Thread.sleep(forTimeInterval: 1.1)
        
        XCTAssertTrue(timer.hasMissedCheckIn)
    }
    
    func testCheckInTimerResetOnSuccess() {
        let timer = CheckInTimer(intervalSeconds: 60, enabled: true)
        let initialRemaining = timer.remainingSeconds
        
        timer.reset()
        
        XCTAssertEqual(timer.remainingSeconds, 60)
        XCTAssertFalse(timer.hasMissedCheckIn)
    }
    
    func testCheckInTimerDisablesNotifications() {
        let timer = CheckInTimer(intervalSeconds: 60, enabled: false)
        XCTAssertFalse(timer.isActive)
    }
    
    func testMultipleCheckInTimers() {
        let timer1 = CheckInTimer(intervalSeconds: 60, enabled: true)
        let timer2 = CheckInTimer(intervalSeconds: 120, enabled: true)
        
        let timers = [timer1, timer2]
        XCTAssertEqual(timers.count, 2)
        XCTAssertTrue(timers.allSatisfy { $0.isActive })
    }
    
    // MARK: - Trusted Circle Rules
    
    func testCircleMemberCanSeeLocationWhenEnabled() {
        let member = CircleMember(
            id: "user1",
            name: "John",
            phoneNumber: "+14155552671",
            role: .member
        )
        
        XCTAssertTrue(sut.canSeeLocation(member: member, isLocationSharingEnabled: true))
    }
    
    func testCircleMemberCannotSeeLocationWhenDisabled() {
        let member = CircleMember(
            id: "user1",
            name: "John",
            phoneNumber: "+14155552671",
            role: .member
        )
        
        XCTAssertFalse(sut.canSeeLocation(member: member, isLocationSharingEnabled: false))
    }
    
    func testCreatorCanAlwaysSeeLocation() {
        let creator = CircleMember(
            id: "creator1",
            name: "Admin",
            phoneNumber: "+14155552671",
            role: .creator
        )
        
        XCTAssertTrue(sut.canSeeLocation(member: creator, isLocationSharingEnabled: false))
    }
    
    func testAdminHasEscalatedPermissions() {
        let admin = CircleMember(
            id: "admin1",
            name: "Admin User",
            phoneNumber: "+14155552671",
            role: .admin
        )
        
        XCTAssertTrue(sut.canReceiveSOSAlert(member: admin))
        XCTAssertTrue(sut.canModifyCircle(member: admin))
    }
    
    // MARK: - Permission Rule Evaluation
    
    func testLocationPermissionRequired() {
        let rule = sut.evaluateLocationPermissions(.denied)
        XCTAssertFalse(rule.canTrack)
        XCTAssertTrue(rule.requiresUserAction)
    }
    
    func testLocationPermissionGranted() {
        let rule = sut.evaluateLocationPermissions(.authorizedAlways)
        XCTAssertTrue(rule.canTrack)
        XCTAssertFalse(rule.requiresUserAction)
    }
    
    func testNotificationPermissionRequired() {
        let rule = sut.evaluateNotificationPermissions(.denied)
        XCTAssertFalse(rule.canSendNotifications)
        XCTAssertTrue(rule.requiresUserAction)
    }
    
    // MARK: - Safety Rule Combinations
    
    func testSOSAndGeofenceInteraction() {
        sut.armSOS()
        
        let geofence = Geofence(
            id: "safe_zone",
            latitude: 37.7749,
            longitude: -122.4194,
            radiusMeters: 100,
            alertOnEntry: true,
            alertOnExit: true
        )
        
        let userLocation = LocationCoordinate(lat: 37.7750, lon: -122.4195)
        
        let geofenceRule = sut.evaluateGeofence(geofence, forLocation: userLocation)
        XCTAssertTrue(geofenceRule.shouldAlert)
        XCTAssertTrue(sut.isSOSActive)
    }
    
    func testCheckInAndSOSState() {
        let timer = CheckInTimer(intervalSeconds: 60, enabled: true)
        sut.armSOS()
        
        XCTAssertTrue(sut.isSOSActive)
        XCTAssertTrue(timer.isActive)
    }
    
    // MARK: - Edge Cases
    
    func testSOSCanBeArmedMultipleTimes() {
        sut.armSOS()
        sut.armSOS()
        XCTAssertEqual(sut.sosState, .armed)
    }
    
    func testGeofenceWithZeroRadius() {
        let geofence = Geofence(
            id: "point",
            latitude: 37.7749,
            longitude: -122.4194,
            radiusMeters: 0,
            alertOnEntry: true,
            alertOnExit: false
        )
        
        let userLocation = LocationCoordinate(lat: 37.7749, lon: -122.4194)
        let rule = sut.evaluateGeofence(geofence, forLocation: userLocation)
        XCTAssertTrue(rule.shouldAlert)
    }
    
    func testCheckInTimerWithZeroInterval() {
        let timer = CheckInTimer(intervalSeconds: 0, enabled: true)
        XCTAssertTrue(timer.hasMissedCheckIn)
    }
}

// MARK: - Test Helpers

enum SafetyEngineError: LocalizedError {
    case sosNotArmed
    case invalidGeofence
    case permissionDenied
}

class SafetyEngine {
    var sosState: SOSState = .disarmed
    var isSOSActive: Bool { sosState == .armed || sosState == .active }
    
    enum SOSState {
        case disarmed, armed, active
    }
    
    func armSOS() {
        sosState = .armed
    }
    
    func disarmSOS() {
        sosState = .disarmed
    }
    
    func triggerSOS() throws {
        guard sosState == .armed else {
            throw SafetyEngineError.sosNotArmed
        }
        sosState = .active
    }
    
    func evaluateGeofence(_ geofence: Geofence, forLocation location: LocationCoordinate) -> GeofenceRule {
        let distance = calculateDistance(from: location, to: geofence)
        let isInside = distance <= Double(geofence.radiusMeters)
        
        var shouldAlert = false
        var alertType: GeofenceAlertType?
        
        if isInside && geofence.alertOnEntry {
            shouldAlert = true
            alertType = .entry
        } else if !isInside && geofence.alertOnExit {
            shouldAlert = true
            alertType = .exit
        }
        
        return GeofenceRule(shouldAlert: shouldAlert, alertType: alertType)
    }
    
    func calculateDistance(from location: LocationCoordinate, to geofence: Geofence) -> Double {
        // Simplified Haversine formula
        let lat1Rad = location.lat * .pi / 180.0
        let lat2Rad = geofence.latitude * .pi / 180.0
        let deltaLat = (geofence.latitude - location.lat) * .pi / 180.0
        let deltaLon = (geofence.longitude - location.lon) * .pi / 180.0
        
        let a = sin(deltaLat / 2) * sin(deltaLat / 2) +
                cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        let radius = 6371000.0 // Earth's radius in meters
        return radius * c
    }
    
    func canSeeLocation(member: CircleMember, isLocationSharingEnabled: Bool) -> Bool {
        if member.role == .creator {
            return true
        }
        return isLocationSharingEnabled
    }
    
    func canReceiveSOSAlert(member: CircleMember) -> Bool {
        return member.role == .admin || member.role == .creator
    }
    
    func canModifyCircle(member: CircleMember) -> Bool {
        return member.role == .admin || member.role == .creator
    }
    
    func evaluateLocationPermissions(_ status: LocationPermissionStatus) -> LocationPermissionRule {
        return LocationPermissionRule(
            canTrack: status == .authorizedAlways || status == .authorizedWhenInUse,
            requiresUserAction: status == .denied
        )
    }
    
    func evaluateNotificationPermissions(_ status: NotificationPermissionStatus) -> NotificationPermissionRule {
        return NotificationPermissionRule(
            canSendNotifications: status == .authorized,
            requiresUserAction: status == .denied
        )
    }
}

// MARK: - Test Models

struct Geofence {
    let id: String
    let latitude: Double
    let longitude: Double
    let radiusMeters: Int
    let alertOnEntry: Bool
    let alertOnExit: Bool
}

struct LocationCoordinate {
    let lat: Double
    let lon: Double
}

struct GeofenceRule {
    let shouldAlert: Bool
    let alertType: GeofenceAlertType?
}

enum GeofenceAlertType {
    case entry, exit
}

struct LocationPermissionRule {
    let canTrack: Bool
    let requiresUserAction: Bool
}

struct NotificationPermissionRule {
    let canSendNotifications: Bool
    let requiresUserAction: Bool
}

enum LocationPermissionStatus {
    case denied, authorizedWhenInUse, authorizedAlways
}

enum NotificationPermissionStatus {
    case denied, authorized
}

class CheckInTimer {
    let intervalSeconds: Int
    let isActive: Bool
    var remainingSeconds: Int
    var hasMissedCheckIn: Bool = false
    private let startTime = Date()
    
    init(intervalSeconds: Int, enabled: Bool) {
        self.intervalSeconds = intervalSeconds
        self.isActive = enabled
        self.remainingSeconds = intervalSeconds
        checkForMissedCheckIn()
    }
    
    func reset() {
        hasMissedCheckIn = false
        remainingSeconds = intervalSeconds
    }
    
    private func checkForMissedCheckIn() {
        if intervalSeconds == 0 {
            hasMissedCheckIn = true
        }
    }
}

extension XCTestCase {
    func XCTAssertNoThrow<T>(_ expression: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) {
        do {
            _ = try expression()
        } catch {
            XCTFail("Threw error: \(error)", file: file, line: line)
        }
    }
}
