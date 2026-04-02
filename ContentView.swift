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
                geofencePage
            }
            .sheet(isPresented: $isShowingAudioRecorder) {
                AudioRecorderView()
            }
            .onAppear {
                guard !isTracking else { return }
                tracker.requestAccess()
                tracker.startTracking()
                geofenceManager.requestNotificationAccess()
                isTracking = true
                loadCircleMembership()
                
                // Set geofence manager's circle membership and auth for alert posting
                let userId = authManager.session?.userId ?? UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
                let circleId = circleRecordID?.recordName ?? "default-circle"
                geofenceManager.setCircleMembership(circleId: circleId, userId: userId)
                
                if let token = authManager.session?.bearerToken {
                    geofenceManager.setBearerToken(token)
                }
            }
            .onReceive(tracker.$lastLocation) { location in
                guard let location else { return }
                region.center = location.coordinate
                cameraPosition = .region(region)
            }
            .onChange(of: authManager.hasConsent) { _, hasConsent in
                tracker.setConsentFlag(hasConsent)
            }
            .navigationTitle("GeoWCS")
        }
    }

    private var routeSections: some View {
        VStack(spacing: 18) {
            // Consent banner — always at top
            consentBanner

            Group {
                switch selectedRoute {
                case .map:
                    mapSection
                case .circle:
                    circleSection
                case .tracker:
                    trackerSection
                case .safety:
                    safetySection
                }
            }
            .id(selectedRoute)
            .transition(routeTransition)

            trackingButton
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $isShowingPaywall) {
            SubscriptionPaywallView()
                .environmentObject(entitlementManager)
        }
    }

    private var consentBanner: some View {
        card(id: "consent-banner") {
            if authManager.hasConsent {
                // Already consented — show confirmation
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Location Sharing Enabled")
                            .font(.subheadline.bold())
                        Text("Your trusted circle can see your location.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        authManager.revokeConsent()
                    } label: {
                        Text("Disable")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                // Awaiting consent
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Location Sharing")
                            .font(.subheadline.bold())
                        Text("Share your exact location with your trusted circle.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { false },
                        set: { _ in authManager.grantConsent() }
                    ))
                    .labelsHidden()
                }
            }
        }
    }

    private var geofencePage: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    geofenceSection
                }
                .padding()
            }
            .navigationTitle("Geofencing")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isShowingGeofencePage = false
                    }
                }
            }
        }
    }

    private var routeTransition: AnyTransition {
        let edge: Edge = routeDirection >= 0 ? .trailing : .leading
        return .asymmetric(
            insertion: .move(edge: edge).combined(with: .opacity),
            removal: .move(edge: routeDirection >= 0 ? .leading : .trailing).combined(with: .opacity)
        )
    }

    private var mapSection: some View {
        ZStack {
            Map(position: $cameraPosition) {
                if let location = tracker.lastLocation {
                    Marker("You", coordinate: location.coordinate)
                }
            }
            .frame(height: 320)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // Overlay for premium-only live map
            if !entitlementManager.isPremium && authManager.hasConsent {
                VStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.yellow)

                    Text("Upgrade to Premium")
                        .font(.headline)

                    Text("See real-time locations of friends in your circles")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Unlock Live Map") {
                        isShowingPaywall = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.yellow)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.3))
                .cornerRadius(14)
            }
        }
    }

    private var circleSection: some View {
        card(id: "circle-membership") {
            sectionHeading("Circle Membership")

            TextField("Circle name", text: $circleName)
                .textFieldStyle(.roundedBorder)

            HStack {
                TextField("Add member name", text: $memberInput)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    let trimmed = memberInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    if !circleMembers.contains(trimmed) {
                        circleMembers.append(trimmed)
                        saveCircleMembership()
                    }
                    memberInput = ""
                }
                .buttonStyle(.bordered)
            }

            ForEach(circleMembers, id: \.self) { member in
                HStack {
                    Text(member)
                    Spacer()
                    Button("Remove") {
                        circleMembers.removeAll { $0 == member }
                        saveCircleMembership()
                    }
                    .buttonStyle(.bordered)
                }
                .font(.caption)
            }

            HStack {
                sectionHeading("Share My Location With Circle")
                Spacer()
                Toggle("", isOn: Binding(
                    get: { tracker.isSharingEnabled },
                    set: { tracker.setSharingConsent($0) }
                ))
                .labelsHidden()
            }

            Text(tracker.isSharingEnabled ? "Consent granted: exact location sharing is ON." : "Consent required: location sharing is OFF.")
                .font(.caption)
                .foregroundStyle(tracker.isSharingEnabled ? .green : .orange)

            Button("Sync Circle To CloudKit") {
                saveCircleMembership()
            }
            .buttonStyle(.bordered)
        }
    }

    private var trackerSection: some View {
        VStack(spacing: 18) {
            card(id: "tracker-trusted") {
                sectionHeading("Trusted Circle")
                HStack(spacing: 8) {
                    ForEach(trustedContacts) { friend in
                        HStack(spacing: 6) {
                            Circle().fill(friend.color).frame(width: 8, height: 8)
                            Text(friend.name)
                                .font(.caption.weight(.semibold))
                            Text(friend.status)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(Capsule())
                    }
                }
            }

            card(id: "tracker-live") {
                sectionHeading("Live Location Tracker")

                if let location = tracker.lastLocation {
                    Text("Lat: \(location.coordinate.latitude, specifier: "%.6f")")
                    Text("Lng: \(location.coordinate.longitude, specifier: "%.6f")")
                    Text("Accuracy: \(location.horizontalAccuracy, specifier: "%.1f") m")
                    Text("Speed: \(tracker.speedKmh, specifier: "%.1f") km/h")
                    Text("Heading: \(tracker.course, specifier: "%.0f")°")
                    if let updatedAt = tracker.updatedAt {
                        Text("Updated: \(updatedAt.formatted(date: .omitted, time: .standard))")
                    }
                } else {
                    Text("No location yet. Tap Start Tracking.")
                }

                Text("Surroundings: \(tracker.surroundingsSummary)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            card(id: "tracker-signals") {
                sectionHeading("Device Signals")
                Text("Battery: \(tracker.batteryLevelPercent)% (\(tracker.batteryStateLabel))")
                Text("Low Power Mode: \(tracker.lowPowerModeEnabled ? "On" : "Off")")
                    .foregroundStyle(tracker.lowPowerModeEnabled ? .orange : .secondary)
            }

            card(id: "tracker-history") {
                sectionHeading("Location History")

                if tracker.locationHistory.isEmpty {
                    Text("History will appear as new points are tracked.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(tracker.locationHistory.prefix(5)) { snapshot in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(snapshot.latitude, specifier: "%.5f"), \(snapshot.longitude, specifier: "%.5f")")
                                .font(.subheadline.weight(.semibold))
                            Text("\(snapshot.timestamp.formatted(date: .omitted, time: .shortened)) • \(snapshot.speedKmh, specifier: "%.1f") km/h")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    private var safetySection: some View {
        VStack(spacing: 16) {
            card(id: "safety-toolkit") {
                sectionHeading("Safety Toolkit")

                HStack {
                    TextField("Designated contact", text: $contactInput)
                        .textFieldStyle(.roundedBorder)
                    Button("Add") {
                        let trimmed = contactInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        if !designatedContacts.contains(trimmed) {
                            designatedContacts.append(trimmed)
                        }
                        contactInput = ""
                    }
                    .buttonStyle(.bordered)
                }

                ForEach(designatedContacts, id: \.self) { contact in
                    HStack {
                        Text(contact)
                        Spacer()
                        Button("Remove") {
                            designatedContacts.removeAll { $0 == contact }
                        }
                        .buttonStyle(.bordered)
                    }
                    .font(.caption)
                }

                Stepper("Missed check-in timer: \(checkInMinutes) min", value: $checkInMinutes, in: 5...120, step: 5)

                HStack(spacing: 10) {
                    Button(checkInArmed ? "Cancel Check-In Timer" : "Arm Check-In Timer") {
                        if checkInArmed {
                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["missed-checkin"])
                            checkInArmed = false
                        } else {
                            scheduleMissedCheckInNotification(afterMinutes: checkInMinutes)
                            checkInArmed = true
                        }
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)

                    Button("Trigger SOS") {
                        triggerSOSEscalation()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }

                if let latest = incidentLog.first {
                    Text("Last incident: \(latest)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Audio Recorder button
            Button {
                isShowingAudioRecorder = true
            } label: {
                HStack {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 20))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Audio Recorder")
                            .font(.subheadline.weight(.semibold))
                        Text("Record & save audio evidence")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }

    private var geofenceSection: some View {
        card(id: "geofence-monitor") {
            sectionHeading("Geofence Monitoring")

            TextField("Geofence name", text: $geofenceName)
                .textFieldStyle(.roundedBorder)

            Button("Arm Geofence Around Current Location (150m)") {
                guard let location = tracker.lastLocation else { return }
                geofenceManager.addGeofence(
                    lat: location.coordinate.latitude,
                    lng: location.coordinate.longitude,
                    radius: 150,
                    id: geofenceName.isEmpty ? "Safe Zone" : geofenceName
                )
            }
            .buttonStyle(.bordered)
            .disabled(tracker.lastLocation == nil)

            ForEach(geofenceManager.geofences) { geofence in
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(geofence.id) • \(Int(geofence.radius))m")
                        .font(.caption.weight(.semibold))
                    HStack {
                        Button("- Radius") {
                            geofenceManager.adjustRadius(id: geofence.id, delta: -25)
                        }
                        .buttonStyle(.bordered)
                        Button("+ Radius") {
                            geofenceManager.adjustRadius(id: geofence.id, delta: 25)
                        }
                        .buttonStyle(.bordered)
                        Button("Remove") {
                            geofenceManager.removeGeofence(id: geofence.id)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
                .padding(.vertical, 2)
            }

            ForEach(geofenceManager.recentEvents.prefix(4), id: \.self) { event in
                Text(event)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var trackingButton: some View {
        Button(isTracking ? "Stop Tracking" : "Start Tracking") {
            if isTracking {
                tracker.stopTracking()
                isTracking = false
            } else {
                tracker.requestAccess()
                tracker.startTracking()
                isTracking = true
            }
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)
    }

    private func card<Content: View>(id: String, @ViewBuilder content: () -> Content) -> some View {
        let isPressed = activeCardID == id

        return VStack(alignment: .leading, spacing: 8) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground).opacity(0.88))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(routeAccent.opacity(0.22), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .scaleEffect(isPressed ? 0.992 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if activeCardID != id {
                        activeCardID = id
                    }
                }
                .onEnded { _ in
                    activeCardID = nil
                }
        )
    }

    private func sectionHeading(_ title: String) -> some View {
        Text(title)
            .font(.system(.title3, design: routeHeadingDesign).weight(.bold))
            .tracking(routeHeadingTracking)
            .foregroundStyle(routeAccent.opacity(0.96))
    }

    private var routeBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SectionRoute.allCases) { route in
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                            routeDirection = (SectionRoute.allCases.firstIndex(of: route) ?? 0) >= (SectionRoute.allCases.firstIndex(of: selectedRoute) ?? 0) ? 1 : -1
                            selectedRoute = route
                        }
                        triggerRouteHaptic()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: route.symbol)
                            Text(route.rawValue)
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(selectedRoute == route ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background {
                            if selectedRoute == route {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(routeAccent)
                                    .matchedGeometryEffect(id: "route-pill", in: routeNamespace)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.42))
                            }
                        }
                    }
                    .buttonStyle(PillPressButtonStyle())
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func moveRoute(direction: Int) {
        guard let currentIndex = SectionRoute.allCases.firstIndex(of: selectedRoute) else { return }
        let nextIndex = max(0, min(SectionRoute.allCases.count - 1, currentIndex + direction))
        let nextRoute = SectionRoute.allCases[nextIndex]
        guard nextRoute != selectedRoute else { return }

        withAnimation(.easeInOut(duration: 0.24)) {
            routeDirection = direction
            selectedRoute = nextRoute
        }
        triggerRouteHaptic()
    }

    private var quickActionStrip: some View {
        HStack(spacing: 10) {
            Button(isTracking ? "Pause" : "Track") {
                if isTracking {
                    tracker.stopTracking()
                    isTracking = false
                } else {
                    tracker.requestAccess()
                    tracker.startTracking()
                    isTracking = true
                }
                triggerImpactHaptic(.light)
            }
            .buttonStyle(.borderedProminent)

            Button("SOS") {
                triggerSOSEscalation()
                triggerSOSWarningHaptic()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)

            Button("Arm Fence") {
                guard let location = tracker.lastLocation else { return }
                geofenceManager.addGeofence(
                    lat: location.coordinate.latitude,
                    lng: location.coordinate.longitude,
                    radius: 150,
                    id: geofenceName.isEmpty ? "Safe Zone" : geofenceName
                )
                triggerImpactHaptic(.medium)
            }
            .buttonStyle(.bordered)
            .disabled(tracker.lastLocation == nil)

            Button("Geofence") {
                isShowingGeofencePage = true
                triggerImpactHaptic(.light)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(routeAccent.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(routeAccent.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
        .padding(.top, 6)
    }

    private func triggerRouteHaptic() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    private func triggerImpactHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    private func triggerSOSWarningHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    private func scheduleMissedCheckInNotification(afterMinutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Missed Check-In"
        content.body = "No check-in received in \(afterMinutes) minutes."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(afterMinutes * 60), repeats: false)
        let request = UNNotificationRequest(identifier: "missed-checkin", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func triggerSOSNotification() {
        let content = UNMutableNotificationContent()
        content.title = "SOS Alert"
        content.body = "Emergency SOS triggered from GeoWCS."
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func triggerSOSEscalation() {
        triggerSOSNotification()

        for (index, contact) in designatedContacts.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "SOS Escalation"
            content.body = "Escalation dispatched to \(contact)"
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(index + 1), repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }

        let incidentText = "\(Date.now.formatted(date: .numeric, time: .shortened)) • SOS sent to \(designatedContacts.joined(separator: ", "))"
        incidentLog.insert(incidentText, at: 0)
        if incidentLog.count > 20 {
            incidentLog.removeLast(incidentLog.count - 20)
        }

        cloudKitManager.saveSOSIncident(
            SOSIncidentRecord(
                userId: UIDevice.current.identifierForVendor?.uuidString ?? "simulator-user",
                contacts: designatedContacts,
                message: "Emergency SOS triggered from GeoWCS.",
                status: "escalated",
                timestamp: Date(),
                lat: tracker.lastLocation?.coordinate.latitude,
                lng: tracker.lastLocation?.coordinate.longitude
            )
        ) { result in
            if case .failure(let error) = result {
                print("SOS incident save failed: \(error.localizedDescription)")
            }
        }
    }

    private func loadCircleMembership() {
        let ownerId = UIDevice.current.identifierForVendor?.uuidString ?? "simulator-user"
        cloudKitManager.fetchCircles(ownerId: ownerId) { result in
            switch result {
            case .success(let circles):
                guard let first = circles.first else { return }
                DispatchQueue.main.async {
                    self.circleName = first.name
                    self.circleMembers = first.members.isEmpty ? self.circleMembers : first.members
                    self.circleRecordID = CKRecord.ID(recordName: first.id)
                }
            case .failure(let error):
                print("Circle fetch failed: \(error.localizedDescription)")
            }
        }
    }

    private func saveCircleMembership() {
        let ownerId = UIDevice.current.identifierForVendor?.uuidString ?? "simulator-user"
        let payload = CircleRecord(name: circleName, members: circleMembers, ownerId: ownerId)
        cloudKitManager.saveCircleSnapshot(recordID: circleRecordID, circle: payload) { result in
            switch result {
            case .success(let snapshot):
                DispatchQueue.main.async {
                    self.circleRecordID = CKRecord.ID(recordName: snapshot.id)
                }
            case .failure(let error):
                print("Circle save failed: \(error.localizedDescription)")
            }
        }
    }
}

private struct PillPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
