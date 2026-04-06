//
//  GeofenceManager.swift
//  GeoWCS - Geofence Alert System
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//

import Foundation
import CoreLocation
import CloudKit
import Combine
import UserNotifications

struct GeofenceConfig: Identifiable {
    let id: String
    var center: CLLocationCoordinate2D
    var radius: Double
}

final class GeofenceManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var recentEvents: [String] = []
    @Published var geofences: [GeofenceConfig] = []

    let locationManager = CLLocationManager()
    private let apiBase: String
    private var circleMembership: (circleId: String, userId: String)?
    private var bearerToken: String?

    override init() {
        let configured = Bundle.main.object(forInfoDictionaryKey: "GeoWCSAPIBase") as? String
        apiBase = configured ?? "http://localhost:3000"
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }

    func setCircleMembership(circleId: String, userId: String) {
        self.circleMembership = (circleId, userId)
    }

    func setBearerToken(_ token: String) {
        self.bearerToken = token
    }

    func requestNotificationAccess() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("Notification permission error: \(error.localizedDescription)")
                return
            }
            print("Notification permission granted: \(granted)")
        }
    }

    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
        requestNotificationAccess()
    }
    
    func addGeofence(lat: Double, lng: Double, radius: Double, id: String) {
        let center = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        let region = CLCircularRegion(center: center, radius: radius, identifier: id)
        region.notifyOnEntry = true
        region.notifyOnExit = true
        appendEvent("Monitoring started for \(id) (\(Int(radius))m)")
        locationManager.startMonitoring(for: region)

        if let existingIndex = geofences.firstIndex(where: { $0.id == id }) {
            geofences[existingIndex] = GeofenceConfig(id: id, center: center, radius: radius)
        } else {
            geofences.insert(GeofenceConfig(id: id, center: center, radius: radius), at: 0)
        }
    }

    func startMonitoring(name: String, center: CLLocationCoordinate2D, radius: Double) {
        addGeofence(
            lat: center.latitude,
            lng: center.longitude,
            radius: radius,
            id: name
        )
    }

    func stopMonitoring() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        geofences.removeAll()
        appendEvent("Stopped monitoring all geofences")
    }

    func removeGeofence(id: String) {
        if let region = locationManager.monitoredRegions.first(where: { $0.identifier == id }) {
            locationManager.stopMonitoring(for: region)
            appendEvent("Stopped monitoring \(id)")
        }
        geofences.removeAll { $0.id == id }
    }

    func adjustRadius(id: String, delta: Double) {
        guard let idx = geofences.firstIndex(where: { $0.id == id }) else { return }
        let current = geofences[idx]
        let newRadius = min(1000, max(50, current.radius + delta))

        removeGeofence(id: id)
        addGeofence(
            lat: current.center.latitude,
            lng: current.center.longitude,
            radius: newRadius,
            id: id
        )
        appendEvent("Updated radius for \(id) to \(Int(newRadius))m")
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        sendAlert("Entered \(region.identifier)", eventType: "entry")
        saveEvent(to: "CloudKit", type: "entry", geofenceId: region.identifier)
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        sendAlert("Exited \(region.identifier)", eventType: "exit")
        saveEvent(to: "CloudKit", type: "exit", geofenceId: region.identifier)
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        let name = region?.identifier ?? "unknown region"
        appendEvent("Monitoring failed for \(name): \(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        appendEvent("Now monitoring \(region.identifier)")
    }
    
    func sendAlert(_ message: String, eventType: String) {
        let content = UNMutableNotificationContent()
        content.title = eventType == "entry" ? "Geofence Entered" : "Geofence Exited"
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Local notification failed: \(error.localizedDescription)")
            }
        }

        appendEvent(message)
    }
    
    func saveEvent(to: String, type: String, geofenceId: String?) {
        appendEvent("Event saved: \(type) -> \(to)")
        postAlertToAPI(type: type, geofenceId: geofenceId)
    }

    private func postAlertToAPI(type: String, geofenceId: String?) {
        guard let (circleId, userId) = circleMembership else {
            print("⚠️  Circle membership not set; skipping alert")
            return
        }

        let alertType = type == "entry" ? "arrival" : "departure"
        let message = "\(type == "entry" ? "Arrived at" : "Left") \(geofenceId ?? "geofence")"

        let payload: [String: Any] = [
            "circleId": circleId,
            "userId": userId,
            "type": alertType,
            "message": message,
            "geofenceId": geofenceId ?? ""
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else { return }

        var request = URLRequest(url: URL(string: "\(apiBase)/v1/alerts")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        request.httpBody = jsonData

        // Add bearer token if available
        if let token = bearerToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error {
                print("❌ Alert API error: \(error.localizedDescription)")
                return
            }

            if let http = response as? HTTPURLResponse {
                if (200..<300).contains(http.statusCode) {
                    print("✅ Alert posted to API: \(alertType)")
                } else {
                    print("⚠️  Alert API returned \(http.statusCode)")
                }
            }
        }.resume()
    }

    private func appendEvent(_ event: String) {
        DispatchQueue.main.async {
            self.recentEvents.insert("\(Date.now.formatted(date: .omitted, time: .shortened)) • \(event)", at: 0)
            if self.recentEvents.count > 10 {
                self.recentEvents.removeLast(self.recentEvents.count - 10)
            }
        }
    }
}
