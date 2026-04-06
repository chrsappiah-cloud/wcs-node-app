import SwiftUI
import MapKit

// MARK: - LiveMapView

/// Full-screen live map that shows:
///   • The device owner's real-time blue dot (heading-aware, powered by
///     `UserAnnotation`) — requires at minimum `.authorizedWhenInUse`.
///   • Every circle member's latest GPS position as a colour-coded pin with
///     a semi-transparent accuracy halo. Pins turn grey when stale (>2 min).
///   • An owner status bar (speed · accuracy · surrounding address).
///
/// The view tightens `LocationTracker` accuracy to
/// `kCLLocationAccuracyBestForNavigation` while visible and relaxes it on
/// dismiss to avoid draining the battery unnecessarily.
///
/// Usage:
/// ```swift
/// LiveMapView(
///     circleId: "my-circle-id",
///     ownerUserId: UIDevice.current.identifierForVendor!.uuidString,
///     tracker: locationTrackerInstance
/// )
/// ```
struct LiveMapView: View {
    @StateObject private var vm: LiveMapViewModel
    @ObservedObject var tracker: LocationTracker

    init(circleId: String, ownerUserId: String, tracker: LocationTracker) {
        _vm = StateObject(wrappedValue: LiveMapViewModel(
            circleId: circleId,
            ownerUserId: ownerUserId
        ))
        self.tracker = tracker
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            liveMap
            OwnerStatusBar(tracker: tracker, fetchError: vm.fetchError)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .onAppear  { vm.startLive(tracker: tracker) }
        .onDisappear { vm.stopLive(tracker: tracker) }
        .navigationTitle("Live Map")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await vm.refreshFriendLocations() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }

    // MARK: - Map

    private var liveMap: some View {
        Map(position: $vm.cameraPosition) {
            // ── Owner ────────────────────────────────────────────────────
            // UserAnnotation renders the standard blue dot with heading
            // cone using the device's CLLocationManager stream directly.
            UserAnnotation()

            // ── Circle members ───────────────────────────────────────────
            ForEach(vm.friendPins) { pin in
                // Accuracy halo — radius matches the GPS horizontal accuracy.
                MapCircle(center: pin.coordinate, radius: max(pin.accuracy, 5))
                    .foregroundStyle(.blue.opacity(0.07))
                    .stroke(.blue.opacity(0.28), lineWidth: 1)

                // Pin with name label.
                Annotation(pin.displayName, coordinate: pin.coordinate, anchor: .bottom) {
                    FriendPinMarker(pin: pin)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - FriendPinMarker

private struct FriendPinMarker: View {
    let pin: FriendPin

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                SwiftUI.Circle()
                    .fill(pin.isStale ? Color(.systemGray3) : Color.accentColor)
                    .frame(width: 38, height: 38)
                    .shadow(color: .black.opacity(0.18), radius: 3, y: 1)

                Image(systemName: "person.fill")
                    .foregroundStyle(.white)
                    .font(.system(size: 17, weight: .semibold))

                // Heading indicator arrow — only when course is valid.
                if pin.heading >= 0 {
                    Image(systemName: "arrow.up")
                        .foregroundStyle(.white.opacity(0.8))
                        .font(.system(size: 8, weight: .black))
                        .rotationEffect(.degrees(pin.heading))
                        .offset(y: -10)
                }
            }

            Text(pin.displayName)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(pin.isStale ? .secondary : .primary)
                .lineLimit(1)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }
}

// MARK: - OwnerStatusBar

private struct OwnerStatusBar: View {
    @ObservedObject var tracker: LocationTracker
    let fetchError: String?

    private var accuracyText: String {
        guard let loc = tracker.lastLocation else { return "–" }
        return String(format: "±%.0f m", loc.horizontalAccuracy)
    }

    var body: some View {
        VStack(spacing: 6) {
            if let error = fetchError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }

            HStack(spacing: 14) {
                Label(
                    String(format: "%.0f km/h", tracker.speedKmh),
                    systemImage: "speedometer"
                )

                Label(accuracyText, systemImage: "location.circle")

                Label(tracker.surroundingsSummary, systemImage: "mappin")
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}
