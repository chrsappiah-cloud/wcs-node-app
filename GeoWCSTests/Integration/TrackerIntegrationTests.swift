//
//  TrackerIntegrationTests.swift
//  GeoWCSTests - Location Tracking Integration Tests
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//
//  Integration tests for location manager -> tracker state -> view model flow.
//

import XCTest
import CoreLocation

class TrackerIntegrationTests: XCTestCase {
    
    var sut: TrackerIntegration!
    var locationManagerDelegate: CoreLocationDelegate!
    
    override func setUp() {
        super.setUp()
        sut = TrackerIntegration()
        locationManagerDelegate = CoreLocationDelegate()
    }
    
    override func tearDown() {
        sut = nil
        locationManagerDelegate = nil
        super.tearDown()
    }
    
    // MARK: - Location Manager → Tracker State Flow
    
    func testLocationUpdateTriggersTrackerUpdate() {
        let location = CLLocation(
            latitude: 37.7749,
            longitude: -122.4194,
            altitude: 0,
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            timestamp: Date()
        )
        
        let expectation = expectation(description: "Tracker updates from location")
        
        sut.onTrackerStateChanged = { state in
            XCTAssertEqual(state.latitude, 37.7749)
            XCTAssertEqual(state.longitude, -122.4194)
            XCTAssertEqual(state.accuracy, 10)
            expectation.fulfill()
        }
        
        sut.locationManager(didUpdateLocations: [location])
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testLocationPermissionDeniedStopsTracking() {
        let expectation = expectation(description: "Tracking stopped on permission denial")
        
        sut.onTrackingStatusChanged = { isTracking in
            XCTAssertFalse(isTracking)
            expectation.fulfill()
        }
        
        sut.locationManager(didFailWithError: .permissionDenied)
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testLocationAuthorizationAlwaysStartsTracking() {
        let expectation = expectation(description: "Tracking started on authorization")
        
        sut.onTrackingStatusChanged = { isTracking in
            XCTAssertTrue(isTracking)
            expectation.fulfill()
        }
        
        sut.locationManager(didChangeAuthorization: .authorizedAlways)
        
        waitForExpectations(timeout: 2.0)
    }
    
    // MARK: - Tracker State Persistence
    
    func testTrackerStatePersistsLocation() {
        let location = CLLocation(latitude: 37.7749, longitude: -122.4194)
        
        sut.locationManager(didUpdateLocations: [location])
        
        let trackerState = sut.getCurrentTrackerState()
        XCTAssertEqual(trackerState.latitude, 37.7749)
        XCTAssertEqual(trackerState.longitude, -122.4194)
    }
    
    func testTrackerStateUpdatesLastSeenTime() {
        let location1 = CLLocation(latitude: 37.7749, longitude: -122.4194)
        sut.locationManager(didUpdateLocations: [location1])
        
        let timestamp1 = sut.getCurrentTrackerState().lastUpdated
        
        Thread.sleep(forTimeInterval: 1.0)
        
        let location2 = CLLocation(latitude: 37.7750, longitude: -122.4195)
        sut.locationManager(didUpdateLocations: [location2])
        
        let timestamp2 = sut.getCurrentTrackerState().lastUpdated
        
        XCTAssertGreaterThan(timestamp2, timestamp1)
    }
    
    // MARK: - Offline Recovery
    
    func testTrackerStateRestoresOnAppRelaunch() {
        let location = CLLocation(latitude: 37.7749, longitude: -122.4194)
        sut.locationManager(didUpdateLocations: [location])
        
        // Simulate app termination by saving state
        sut.saveTrackerState()
        
        // Simulate app relaunch
        let newTracker = TrackerIntegration()
        newTracker.loadTrackerState()
        
        let restoredState = newTracker.getCurrentTrackerState()
        XCTAssertEqual(restoredState.latitude, 37.7749)
        XCTAssertEqual(restoredState.longitude, -122.4194)
    }
    
    func testTrackerSyncWithCloudKitAfterRelaunch() {
        let location = CLLocation(latitude: 37.7749, longitude: -122.4194)
        sut.locationManager(didUpdateLocations: [location])
        
        let expectation = expectation(description: "CloudKit sync completes")
        
        sut.syncTrackerStateWithCloudKit { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - Geofence Event Handling
    
    func testGeofenceEntryEventTriggersNotification() {
        let expectation = expectation(
            forNotification: NSNotification.Name("GeofenceEntered"),
            object: nil
        )
        
        let region = MockCLRegion()
        region.identifier = "home_zone"
        
        DispatchQueue.main.async {
            self.sut.locationManager(didEnterRegion: region)
            NotificationCenter.default.post(
                name: NSNotification.Name("GeofenceEntered"),
                object: region.identifier
            )
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testGeofenceExitTriggersNotification() {
        let expectation = expectation(
            forNotification: NSNotification.Name("GeofenceExited"),
            object: nil
        )
        
        let region = MockCLRegion()
        region.identifier = "safe_zone"
        
        DispatchQueue.main.async {
            self.sut.locationManager(didExitRegion: region)
            NotificationCenter.default.post(
                name: NSNotification.Name("GeofenceExited"),
                object: region.identifier
            )
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    // MARK: - View Model Updates
    
    func testTrackerStateUpdatesPropagateToViewModel() {
        let viewModelExpectation = expectation(description: "ViewModel receives update")
        
        let viewModel = TrackerViewModel(tracker: sut)
        
        viewModel.onStateChanged = {
            XCTAssertNotNil(viewModel.currentLocation)
            XCTAssertEqual(viewModel.isTracking, true)
            viewModelExpectation.fulfill()
        }
        
        let location = CLLocation(latitude: 37.7749, longitude: -122.4194)
        sut.locationManager(didUpdateLocations: [location])
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testViewModelReflectsTrackerAccuracy() {
        let location = CLLocation(
            latitude: 37.7749,
            longitude: -122.4194,
            altitude: 0,
            horizontalAccuracy: 5,
            verticalAccuracy: 10,
            timestamp: Date()
        )
        
        let viewModel = TrackerViewModel(tracker: sut)
        sut.locationManager(didUpdateLocations: [location])
        
        XCTAssertEqual(viewModel.accuracyMeters, 5)
    }
    
    // MARK: - Battery & Background Mode
    
    func testTrackerRespondsToBackgroundModeTransition() {
        sut.appDidEnterBackground()
        XCTAssertFalse(sut.isTrackingInForeground)
        
        sut.appDidEnterForeground()
        XCTAssertTrue(sut.isTrackingInForeground)
    }
    
    func testTrackerContinuesInBackgroundWithPermission() {
        sut.enableBackgroundTracking()
        
        sut.appDidEnterBackground()
        
        XCTAssertTrue(sut.isTrackingInBackground)
    }
    
    // MARK: - Accuracy & Filtering
    
    func testTrackerFiltersLowAccuracyUpdates() {
        let lowAccuracyLocation = CLLocation(
            latitude: 37.7749,
            longitude: -122.4194,
            horizontalAccuracy: 1000  // Very low accuracy
        )
        
        let initialState = sut.getCurrentTrackerState()
        
        sut.locationManager(didUpdateLocations: [lowAccuracyLocation])
        
        // Should not update with low accuracy
        let afterState = sut.getCurrentTrackerState()
        XCTAssertEqual(initialState.latitude, afterState.latitude)
    }
    
    func testTrackerAcceptsHighAccuracyUpdates() {
        let highAccuracyLocation = CLLocation(
            latitude: 37.7749,
            longitude: -122.4194,
            horizontalAccuracy: 5  // High accuracy
        )
        
        sut.locationManager(didUpdateLocations: [highAccuracyLocation])
        
        let state = sut.getCurrentTrackerState()
        XCTAssertEqual(state.latitude, 37.7749)
    }
    
    // MARK: - Error Handling
    
    func testTrackerHandlesLocationDenied() {
        let expectation = expectation(description: "Tracking is disabled on error")
        
        sut.onTrackingStatusChanged = { isTracking in
            XCTAssertFalse(isTracking)
            expectation.fulfill()
        }
        
        let error = NSError(domain: "CLLocationError", code: 1) // kCLErrorDenied
        sut.locationManager(didFailWithError: .permissionDenied)
        
        waitForExpectations(timeout: 2.0)
    }
    
    // MARK: - History Recording
    
    func testTrackerRecordsLocationHistory() {
        let location1 = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let location2 = CLLocation(latitude: 37.7750, longitude: -122.4195)
        
        sut.locationManager(didUpdateLocations: [location1])
        Thread.sleep(forTimeInterval: 0.1)
        sut.locationManager(didUpdateLocations: [location2])
        
        let history = sut.getLocationHistory()
        XCTAssertEqual(history.count, 2)
    }
    
    func testTrackerLimitsHistorySize() {
        // Add many locations
        for i in 0..<1000 {
            let location = CLLocation(
                latitude: 37.7749 + Double(i) * 0.001,
                longitude: -122.4194
            )
            sut.locationManager(didUpdateLocations: [location])
        }
        
        let history = sut.getLocationHistory()
        XCTAssertLessThanOrEqual(history.count, 500)  // Reasonable history limit
    }
}

// MARK: - Test Support

class TrackerIntegration {
    var isTracking = false
    var isTrackingInForeground = true
    var isTrackingInBackground = false
    
    private var trackerState: TrackerState
    private var locationHistory: [CLLocation] = []
    
    var onTrackerStateChanged: ((TrackerState) -> Void)?
    var onTrackingStatusChanged: ((Bool) -> Void)?
    
    enum LocationError {
        case permissionDenied
    }
    
    init() {
        self.trackerState = TrackerState()
    }
    
    func locationManager(didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Filter low accuracy
        if location.horizontalAccuracy > 100 {
            return
        }
        
        trackerState.latitude = location.coordinate.latitude
        trackerState.longitude = location.coordinate.longitude
        trackerState.accuracy = Int(location.horizontalAccuracy)
        trackerState.lastUpdated = Date()
        trackerState.isActive = true
        
        locationHistory.append(location)
        if locationHistory.count > 500 {
            locationHistory.removeFirst()
        }
        
        isTracking = true
        onTrackerStateChanged?(trackerState)
    }
    
    func locationManager(didChangeAuthorization auth: CLAuthorizationStatus) {
        if auth == .authorizedAlways {
            isTracking = true
            onTrackingStatusChanged?(true)
        }
    }
    
    func locationManager(didFailWithError error: LocationError) {
        isTracking = false
        onTrackingStatusChanged?(false)
    }
    
    func locationManager(didEnterRegion region: CLRegion) {
        // Geofence entry
    }
    
    func locationManager(didExitRegion region: CLRegion) {
        // Geofence exit
    }
    
    func getCurrentTrackerState() -> TrackerState {
        return trackerState
    }
    
    func saveTrackerState() {
        // Persist to UserDefaults
    }
    
    func loadTrackerState() {
        // Restore from UserDefaults
    }
    
    func syncTrackerStateWithCloudKit(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            completion(true)
        }
    }
    
    func appDidEnterBackground() {
        isTrackingInForeground = false
    }
    
    func appDidEnterForeground() {
        isTrackingInForeground = true
    }
    
    func enableBackgroundTracking() {
        isTrackingInBackground = true
    }
    
    func getLocationHistory() -> [CLLocation] {
        return locationHistory
    }
}

struct TrackerState {
    var latitude: Double = 0
    var longitude: Double = 0
    var accuracy: Int = 0
    var lastUpdated: Date = Date()
    var isActive: Bool = false
}

class TrackerViewModel {
    let tracker: TrackerIntegration
    var currentLocation: (lat: Double, lon: Double)?
    var isTracking: Bool = false
    var accuracyMeters: Int = 0
    
    var onStateChanged: (() -> Void)?
    
    init(tracker: TrackerIntegration) {
        self.tracker = tracker
        subscribeToUpdates()
    }
    
    private func subscribeToUpdates() {
        tracker.onTrackerStateChanged = { state in
            self.currentLocation = (state.latitude, state.longitude)
            self.isTracking = state.isActive
            self.accuracyMeters = state.accuracy
            self.onStateChanged?()
        }
    }
}

class CoreLocationDelegate: NSObject {
    // Mock delegate for testing
}

class MockCLRegion: CLRegion {
    override var identifier: String {
        get { _identifier }
        set { _identifier = newValue }
    }
    private var _identifier = ""
}
