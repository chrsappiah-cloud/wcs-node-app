//
//  ContentView.swift
//  GeoWCS
//
//  Created by Christopher Appiah-Thompson on 1/4/2026.
//  Copyright © 2026 World Class Scholars. All rights reserved.
//
//  Developed under the leadership of Dr. Christopher Appiah-Thompson
//

import SwiftUI
import MapKit
import CoreLocation
import UserNotifications
import CloudKit
import UIKit

struct TrustedContact: Identifiable {
    let id = UUID()
    let name: String
    let status: String
    let color: Color
}

struct ContentView: View {
    enum SectionRoute: String, CaseIterable, Identifiable {
        case map = "Map"
        case circle = "Circle"
        case tracker = "Tracker"
        case safety = "Safety"

        var id: String { rawValue }

        var symbol: String {
            switch self {
            case .map: return "map.fill"
            case .circle: return "person.3.fill"
            case .tracker: return "location.viewfinder"
            case .safety: return "shield.lefthalf.filled"
            }
        }
    }

    @Namespace private var routeNamespace

    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @StateObject private var tracker = LocationTracker()
    @StateObject private var geofenceManager = GeofenceManager()
    private let cloudKitManager = CloudKitManager()
    @State private var isShowingPaywall = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    @State private var isTracking = false
    @State private var geofenceName = "Home Safe Zone"
    @State private var checkInMinutes = 15
    @State private var checkInArmed = false
    @State private var circleName = "Family Core"
    @State private var memberInput = ""
    @State private var circleMembers: [String] = ["Maya", "Kojo", "Avery"]
    @State private var circleRecordID: CKRecord.ID?
    @State private var designatedContacts: [String] = ["Maya", "Kojo"]
    @State private var contactInput = ""
    @State private var incidentLog: [String] = []
    @State private var selectedRoute: SectionRoute = .map
    @State private var routeDirection: Int = 1
    @State private var activeCardID: String?
    @State private var isShowingGeofencePage = false
    @State private var isShowingAudioRecorder = false
    @State private var isShowingAuthDiagnostics = false

    private var trustedContacts: [TrustedContact] {
        circleMembers.enumerated().map { index, name in
            let status: String
            let color: Color
            switch index % 3 {
            case 0:
                status = "online"
                color = .green
            case 1:
                status = "idle"
                color = .orange
            default:
                status = "offline"
                color = .gray
            }
            return TrustedContact(name: name, status: status, color: color)
        }
    }

    private var routeAccent: Color {
        switch selectedRoute {
        case .map: return .blue
        case .circle: return .indigo
        case .tracker: return .cyan
        case .safety: return .orange
        }
    }

    private var routeCanvas: LinearGradient {
        switch selectedRoute {
        case .map:
            return LinearGradient(colors: [Color(red: 0.89, green: 0.95, blue: 1.0), Color(red: 0.84, green: 0.93, blue: 0.95)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .circle:
            return LinearGradient(colors: [Color(red: 0.93, green: 0.91, blue: 1.0), Color(red: 0.89, green: 0.95, blue: 1.0)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .tracker:
            return LinearGradient(colors: [Color(red: 0.88, green: 0.98, blue: 1.0), Color(red: 0.86, green: 0.93, blue: 1.0)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .safety:
            return LinearGradient(colors: [Color(red: 1.0, green: 0.95, blue: 0.89), Color(red: 1.0, green: 0.9, blue: 0.88)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var routeHeadingDesign: Font.Design {
        switch selectedRoute {
        case .map: return .rounded
        case .circle: return .serif
        case .tracker: return .monospaced
        case .safety: return .rounded
        }
    }

    private var routeHeadingTracking: CGFloat {
        switch selectedRoute {
        case .map: return 0.1
        case .circle: return 0.2
        case .tracker: return 0.0
        case .safety: return 0.25
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                routeCanvas
                    .ignoresSafeArea()

                VStack(spacing: 10) {
                    routeBar

                    ScrollView {
                        routeSections
                    }
                    .padding(.horizontal)
                    .animation(.spring(response: 0.34, dampingFraction: 0.84), value: selectedRoute)
                    .gesture(
                        DragGesture(minimumDistance: 25)
                            .onEnded { value in
                                if value.translation.width < -80 {
                                    moveRoute(direction: 1)
                                } else if value.translation.width > 80 {
                                    moveRoute(direction: -1)
                                }
                            }
                    )
                }
            }
            .safeAreaInset(edge: .bottom) {
                quickActionStrip
            }
            .sheet(isPresented: $isShowingGeofencePage) {
                geofenceSheet
            }
            .sheet(isPresented: $isShowingAudioRecorder) {
                AudioRecorderView()
            }
            .sheet(isPresented: $isShowingAuthDiagnostics) {
                AuthDiagnosticsView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $isShowingPaywall) {
                SubscriptionPaywallView()
                    .environmentObject(entitlementManager)
            }
            .navigationTitle("GeoWCS")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Label(authManager.session?.phoneNumber ?? "", systemImage: "person.crop.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .opacity(authManager.session?.phoneNumber == nil ? 0 : 1)
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    if !entitlementManager.isPremium {
                        Button("Upgrade") {
                            isShowingPaywall = true
                        }
                    }

                    Menu {
                        Button("Auth Diagnostics") {
                            isShowingAuthDiagnostics = true
                        }

                        Button("Sign Out", role: .destructive) {
                            authManager.signOut()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .task {
                geofenceManager.requestAuthorization()
                tracker.requestAccess()
            }
        }
    }

    private var routeBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(SectionRoute.allCases) { route in
                    Button {
                        routeDirection = transitionDirection(from: selectedRoute, to: route)
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                            selectedRoute = route
                            activeCardID = nil
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: route.symbol)
                            Text(route.rawValue)
                                .font(.system(.subheadline, design: route == selectedRoute ? routeHeadingDesign : .rounded).weight(.semibold))
                                .tracking(route == selectedRoute ? routeHeadingTracking : 0.1)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            ZStack {
                                Capsule()
                                    .fill(route == selectedRoute ? routeAccent.opacity(0.24) : Color.white.opacity(0.55))
                                if route == selectedRoute {
                                    Capsule()
                                        .stroke(routeAccent.opacity(0.55), lineWidth: 1)
                                }
                            }
                        )
                        .foregroundStyle(route == selectedRoute ? routeAccent : .primary)
                    }
                    .buttonStyle(.plain)
                    .matchedGeometryEffect(id: route.rawValue, in: routeNamespace)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    @ViewBuilder
    private var routeSections: some View {
        VStack(spacing: 16) {
            switch selectedRoute {
            case .map:
                mapSection
                    .id("map")
                    .transition(routeTransition)
            case .circle:
                circleSection
                    .id("circle")
                    .transition(routeTransition)
            case .tracker:
                trackerSection
                    .id("tracker")
                    .transition(routeTransition)
            case .safety:
                safetySection
                    .id("safety")
                    .transition(routeTransition)
            }
        }
        .padding(.bottom, 80)
    }

    private var routeTransition: AnyTransition {
        let insertionEdge: Edge = routeDirection >= 0 ? .trailing : .leading
        let removalEdge: Edge = routeDirection >= 0 ? .leading : .trailing
        return .asymmetric(
            insertion: .move(edge: insertionEdge).combined(with: .opacity),
            removal: .move(edge: removalEdge).combined(with: .opacity)
        )
    }

    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Live Map", systemImage: "map.fill")
                    .font(.headline)
                Spacer()
                Text(isTracking ? "Tracking" : "Idle")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background((isTracking ? Color.green : Color.gray).opacity(0.2))
                    .clipShape(Capsule())
            }

            LiveMapView(
                circleId: circleRecordID?.recordName ?? "local-circle",
                ownerUserId: authManager.session?.userId ?? "local-user",
                tracker: tracker
            )
            .frame(minHeight: 360)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)

            HStack(spacing: 10) {
                Button {
                    isTracking.toggle()
                    if isTracking {
                        tracker.startTracking()
                        geofenceManager.startMonitoring(name: geofenceName, center: region.center, radius: 150)
                    } else {
                        tracker.stopTracking()
                        geofenceManager.stopMonitoring()
                    }
                } label: {
                    Label(isTracking ? "Stop" : "Start", systemImage: isTracking ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    isShowingGeofencePage = true
                } label: {
                    Label("Geofence", systemImage: "mappin.and.ellipse")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.white.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var circleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Circle", systemImage: "person.3.fill")
                    .font(.headline)
                Spacer()
                if let recordID = circleRecordID {
                    Text(recordID.recordName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            HStack(spacing: 10) {
                TextField("Circle name", text: $circleName)
                    .textFieldStyle(.roundedBorder)
                Button("Save") {
                    saveCircle()
                }
                .buttonStyle(.borderedProminent)
            }

            HStack(spacing: 10) {
                TextField("Add member", text: $memberInput)
                    .textFieldStyle(.roundedBorder)
                Button {
                    let trimmed = memberInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    circleMembers.append(trimmed)
                    memberInput = ""
                    saveCircle()
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.bordered)
            }

            ForEach(trustedContacts) { contact in
                HStack(spacing: 10) {
                    SwiftUI.Circle()
                        .fill(contact.color)
                        .frame(width: 10, height: 10)
                    Text(contact.name)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(contact.status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.white.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var trackerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Tracker", systemImage: "location.viewfinder")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Check-in timer")
                    .font(.subheadline.weight(.semibold))
                Stepper("Every \(checkInMinutes) minutes", value: $checkInMinutes, in: 5...60, step: 5)

                Toggle("Armed", isOn: $checkInArmed)
                    .toggleStyle(.switch)
            }

            HStack(spacing: 10) {
                TextField("Contact", text: $contactInput)
                    .textFieldStyle(.roundedBorder)
                Button {
                    let trimmed = contactInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    designatedContacts.append(trimmed)
                    contactInput = ""
                } label: {
                    Label("Add", systemImage: "person.badge.plus")
                }
                .buttonStyle(.bordered)
            }

            if designatedContacts.isEmpty {
                Text("No designated contacts yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(designatedContacts, id: \.self) { name in
                    HStack {
                        Text(name)
                        Spacer()
                        Button(role: .destructive) {
                            designatedContacts.removeAll { $0 == name }
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var safetySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Safety", systemImage: "shield.lefthalf.filled")
                .font(.headline)

            Button(role: .destructive) {
                let message = "SOS triggered at \(Date().formatted(date: .omitted, time: .standard))"
                incidentLog.insert(message, at: 0)
                notifyContacts(message: message)
            } label: {
                Label("Trigger SOS", systemImage: "exclamationmark.triangle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            if incidentLog.isEmpty {
                Text("No incidents logged")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(incidentLog, id: \.self) { event in
                    Text(event)
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var quickActionStrip: some View {
        HStack(spacing: 10) {
            Button {
                routeDirection = transitionDirection(from: selectedRoute, to: .map)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
                    selectedRoute = .map
                }
            } label: {
                Label("Map", systemImage: "map")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                routeDirection = transitionDirection(from: selectedRoute, to: .safety)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
                    selectedRoute = .safety
                }
            } label: {
                Label("SOS", systemImage: "bolt.shield")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }

    private var geofenceSheet: some View {
        NavigationStack {
            Form {
                Section("Geofence") {
                    TextField("Name", text: $geofenceName)
                    HStack {
                        Text("Latitude")
                        Spacer()
                        Text("\(region.center.latitude, specifier: "%.5f")")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Longitude")
                        Spacer()
                        Text("\(region.center.longitude, specifier: "%.5f")")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button("Save Monitoring Region") {
                        geofenceManager.startMonitoring(name: geofenceName, center: region.center, radius: 150)
                        isShowingGeofencePage = false
                    }
                }
            }
            .navigationTitle("Geofence")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { isShowingGeofencePage = false }
                }
            }
        }
    }

    private func moveRoute(direction: Int) {
        let routes = SectionRoute.allCases
        guard let index = routes.firstIndex(of: selectedRoute) else { return }
        let next = (index + direction + routes.count) % routes.count
        routeDirection = direction
        withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
            selectedRoute = routes[next]
            activeCardID = nil
        }
    }

    private func transitionDirection(from current: SectionRoute, to next: SectionRoute) -> Int {
        let routes = SectionRoute.allCases
        guard let currentIndex = routes.firstIndex(of: current),
              let nextIndex = routes.firstIndex(of: next) else {
            return 1
        }
        return nextIndex >= currentIndex ? 1 : -1
    }

    private func saveCircle() {
        cloudKitManager.saveCircle(name: circleName, members: circleMembers, recordID: circleRecordID) { result in
            switch result {
            case .success(let record):
                DispatchQueue.main.async {
                    self.circleRecordID = record.recordID
                }
            case .failure(let error):
                print("❌ Failed saving circle: \(error.localizedDescription)")
            }
        }
    }

    private func notifyContacts(message: String) {
        for contact in designatedContacts {
            print("Notifying \(contact): \(message)")
        }

        let content = UNMutableNotificationContent()
        content.title = "GeoWCS Safety Alert"
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
