//
//  PushNotificationManager.swift
//  GeoWCS - Apple Push Notifications
//
//  Copyright © 2026 World Class Scholars. All rights reserved.
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//

import Combine
import Foundation
import UserNotifications

/// Manages device push notification registration and payload handling.
@MainActor
final class PushNotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {

    @Published var deviceToken: String?
    @Published var lastNotification: UNNotificationResponse?
    @Published private(set) var isRegistered = false

    static let shared = PushNotificationManager()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Registration

    /// Request user permission and register for remote notifications.
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("❌ Notification auth error: \(error.localizedDescription)")
                completion(false)
                return
            }

            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }

            DispatchQueue.main.async {
                self.isRegistered = granted
                completion(granted)
            }
        }
    }

    /// Called when the app receives a device token from APNs.
    func didRegisterForRemoteNotifications(deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        self.deviceToken = token
        print("📱 Device token registered: \(token)")
    }

    /// Called when remote notification registration fails.
    func didFailToRegisterForRemoteNotifications(error: Error) {
        print("⚠️  Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // MARK: - Notification handling

    /// Called when a notification arrives while the app is in the foreground.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo

        // Parse alert properties
        let alertType = userInfo["alertType"] as? String ?? "unknown"
        let circleId = userInfo["circleId"] as? String
        let userId = userInfo["userId"] as? String
        let geofenceId = userInfo["geofenceId"] as? String

        print("🔔 Foreground notification: type=\(alertType) circle=\(circleId ?? "?") geofence=\(geofenceId ?? "?")")

        // Show banner even in foreground; play sound and update badge
        completionHandler([.banner, .sound, .badge])

        DispatchQueue.main.async {
            self.handleNotificationPayload(
                alertType: alertType,
                circleId: circleId,
                userId: userId,
                geofenceId: geofenceId
            )
        }
    }

    /// Called when user taps a notification or it arrives in the background.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        let alertType = userInfo["alertType"] as? String ?? "unknown"
        let circleId = userInfo["circleId"] as? String
        let userId = userInfo["userId"] as? String
        let geofenceId = userInfo["geofenceId"] as? String

        print("📲 Notification tapped: type=\(alertType)")

        Task { @MainActor in
            self.lastNotification = response
            self.handleNotificationPayload(
                alertType: alertType,
                circleId: circleId,
                userId: userId,
                geofenceId: geofenceId
            )
            completionHandler()
        }
    }

    // MARK: - Private

    /// Handles the payload and triggers app state updates.
    private func handleNotificationPayload(
        alertType: String,
        circleId: String?,
        userId: String?,
        geofenceId: String?
    ) {
        switch alertType {
        case "geofence_entry":
            print("📍 Geofence entry alert for \(geofenceId ?? "unknown")")
        case "geofence_exit":
            print("📍 Geofence exit alert for \(geofenceId ?? "unknown")")
        case "sos":
            print("🆘 SOS alert from user \(userId ?? "unknown")")
        case "low_battery":
            print("🔋 Low battery alert from \(userId ?? "unknown")")
        case "device_offline":
            print("📡 Device offline alert for \(userId ?? "unknown")")
        case "inactivity":
            print("⏱️  Inactivity alert for \(userId ?? "unknown")")
        default:
            print("❓ Unknown alert type: \(alertType)")
        }
    }
}
