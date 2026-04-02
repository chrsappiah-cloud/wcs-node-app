//
//  LocationTracker.swift
//  GeoWCS - Real-Time Location Tracking
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//

import Foundation
import CoreLocation
import Combine
import CloudKit
import UIKit
import MapKit

struct SurroundingsFormatter {
    static func format(components: [String?], fallbackName: String?) -> String {
        let normalized = components.compactMap { value -> String? in
            guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
                return nil
            }
            return trimmed
        }

        var seen = Set<String>()
        let uniqueComponents = normalized.filter { seen.insert($0).inserted }

        if uniqueComponents.isEmpty {
            if let fallback = fallbackName?.trimmingCharacters(in: .whitespacesAndNewlines), !fallback.isEmpty {
                return fallback
            }
            return "Nearby area"
        }

        return uniqueComponents.joined(separator: ", ")
    }
}

struct LocationSnapshot: Identifiable {
    let id = UUID()
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let speedKmh: Double
}

final class LocationTracker: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastLocation: CLLocation?
    @Published var speedKmh: Double = 0
    @Published var course: Double = 0
    @Published var updatedAt: Date?
    @Published var isSharingEnabled: Bool = false
    @Published var hasConsent: Bool = false
    @Published var surroundingsSummary: String = "Detecting surroundings..."
    @Published var batteryLevelPercent: Int = 0
    @Published var batteryStateLabel: String = "unknown"
    @Published var lowPowerModeEnabled: Bool = false
    @Published var locationHistory: [LocationSnapshot] = []

    private let manager = CLLocationManager()
    private let cloudKitManager = CloudKitManager()
    private var lastCloudSaveAt: Date?
    private var lastGeocodeAt: Date?
    private var activeCircleId: String?
    private var cloudSaveThrottleSeconds: TimeInterval = 10
    private let geocodeThrottleSeconds: TimeInterval = 15

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        manager.pausesLocationUpdatesAutomatically = true

        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBatteryOrPowerStateChange),
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBatteryOrPowerStateChange),
            name: UIDevice.batteryStateDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBatteryOrPowerStateChange),
            name: Notification.Name.NSProcessInfoPowerStateDidChange,
            object: nil
        )
        updateBatteryState()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func requestAccess() {
        manager.requestAlwaysAuthorization()
    }

    /// Call with the circle the owner is actively broadcasting into so that
    /// CloudKit location events are tagged with the correct `circleId`.
    func setActiveCircleId(_ id: String?) {
        activeCircleId = id
    }

    /// Tightens GPS accuracy and CloudKit throttle while the live map is
    /// visible, then relaxes them to preserve battery when dismissed.
    func setLiveMapActive(_ active: Bool) {
        if active {
            manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            manager.distanceFilter = 2
            manager.pausesLocationUpdatesAutomatically = false
            cloudSaveThrottleSeconds = 5
        } else {
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.distanceFilter = 5
            manager.pausesLocationUpdatesAutomatically = true
            cloudSaveThrottleSeconds = 10
        }
    }

    func startTracking() {
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func stopTracking() {
        manager.stopUpdatingLocation()
    }

    func setSharingConsent(_ enabled: Bool) {
        isSharingEnabled = enabled
    }

    func setConsentFlag(_ consented: Bool) {
        hasConsent = consented
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startTracking()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        speedKmh = max(0, location.speed) * 3.6
        course = location.course >= 0 ? location.course : 0
        updatedAt = Date()

        locationHistory.insert(
            LocationSnapshot(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                timestamp: Date(),
                speedKmh: speedKmh
            ),
            at: 0
        )
        if locationHistory.count > 20 {
            locationHistory.removeLast(locationHistory.count - 20)
        }

        updateSurroundingsIfNeeded(location)
        // Only publish to CloudKit if user has granted consent AND enabled sharing
        if isSharingEnabled && hasConsent {
            persistLocationToCloudKitIfNeeded(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location tracking error: \(error.localizedDescription)")
    }

    private func persistLocationToCloudKitIfNeeded(_ location: CLLocation) {
        let now = Date()
        if let lastCloudSaveAt, now.timeIntervalSince(lastCloudSaveAt) < cloudSaveThrottleSeconds {
            return
        }

        let userId = UIDevice.current.identifierForVendor?.uuidString ?? "simulator-user"
        let record = LocationRecord(
            lat: location.coordinate.latitude,
            lng: location.coordinate.longitude,
            timestamp: now,
            userId: userId,
            accuracy: location.horizontalAccuracy,
            speedKmh: speedKmh,
            heading: course
        )

        cloudKitManager.saveLocation(record, circleId: activeCircleId) { [weak self] result in
            switch result {
            case .success(let recordId):
                self?.lastCloudSaveAt = now
                print("CloudKit save success: \(recordId.recordName)")
            case .failure(let error):
                print("CloudKit save failed: \(error.localizedDescription)")
            }
        }
    }

    private func updateSurroundingsIfNeeded(_ location: CLLocation) {
        let now = Date()
        if let lastGeocodeAt, now.timeIntervalSince(lastGeocodeAt) < geocodeThrottleSeconds {
            return
        }

        lastGeocodeAt = now
        reverseGeocodeWithMapKit(location)
    }

    private func reverseGeocodeWithMapKit(_ location: CLLocation) {
        Task { [weak self] in
            do {
                guard let request = MKReverseGeocodingRequest(location: location) else {
                    self?.surroundingsSummary = "Surroundings unavailable: invalid geocoding request"
                    return
                }
                let mapItems = try await request.mapItems
                guard let placemark = mapItems.first?.placemark else {
                    self?.surroundingsSummary = "Nearby area"
                    return
                }

                self?.surroundingsSummary = formattedSurroundings(from: placemark)
            } catch {
                self?.surroundingsSummary = "Surroundings unavailable: \(error.localizedDescription)"
            }
        }
    }

    private func formattedSurroundings(from placemark: MKPlacemark) -> String {
        SurroundingsFormatter.format(
            components: [
                placemark.subLocality,
                placemark.locality,
                placemark.subAdministrativeArea,
                placemark.administrativeArea,
                placemark.country
            ],
            fallbackName: placemark.name
        )
    }

    @objc
    private func handleBatteryOrPowerStateChange() {
        updateBatteryState()
    }

    private func updateBatteryState() {
        let level = UIDevice.current.batteryLevel
        if level >= 0 {
            batteryLevelPercent = Int(level * 100)
        } else {
            batteryLevelPercent = 0
        }

        switch UIDevice.current.batteryState {
        case .charging:
            batteryStateLabel = "charging"
        case .full:
            batteryStateLabel = "full"
        case .unplugged:
            batteryStateLabel = "unplugged"
        default:
            batteryStateLabel = "unknown"
        }

        lowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
    }
}
