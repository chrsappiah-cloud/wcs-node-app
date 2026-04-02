//
//  GeoWCSApp.swift
//  GeoWCS
//
//  Created by Christopher Appiah-Thompson  on 1/4/2026.
//

import SwiftUI
import StoreKit
import UIKit

@main
struct GeoWCSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var authManager = AuthManager()
    @StateObject private var entitlementManager = EntitlementManager()

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.session != nil {
                    ContentView()
                        .environmentObject(authManager)
                        .environmentObject(entitlementManager)
                } else {
                    SignInView()
                        .environmentObject(authManager)
                        .environmentObject(entitlementManager)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: authManager.session != nil)
            .onAppear { requestNotificationPermissions() }
        }
    }

    private func requestNotificationPermissions() {
        PushNotificationManager.shared.requestAuthorization { granted in
            if granted {
                print("✅ Push notifications enabled")
            }
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        PushNotificationManager.shared.didRegisterForRemoteNotifications(deviceToken: deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        PushNotificationManager.shared.didFailToRegisterForRemoteNotifications(error: error)
    }
}
