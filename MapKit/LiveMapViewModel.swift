import Foundation
import Combine
import CloudKit
import CoreLocation
import MapKit
import SwiftUI

/// Drives the live map: polls CloudKit for every circle member's latest
/// position and exposes a `MapCameraPosition` that follows the owner's
/// real-time heading.
@MainActor
final class LiveMapViewModel: ObservableObject {
    // MARK: - Published state

    @Published var friendPins: [FriendPin] = []
    @Published var cameraPosition: MapCameraPosition = .userLocation(
        followsHeading: true,
        fallback: .automatic
    )
    @Published var fetchError: String?

    // MARK: - Private

    private let circleId: String
    /// The device owner's userId — excluded from the friends list since they
    /// are already shown via `UserAnnotation()`.
    private let ownerUserId: String
    private let cloudKit = CloudKitManager()
    private var pollTask: Task<Void, Never>?
    /// Safety-net re-poll interval (seconds). CKSubscription push covers most
    /// updates in real time; this catches any missed silent pushes.
    private let pollIntervalSeconds: TimeInterval = 8

    // MARK: - Init

    init(circleId: String, ownerUserId: String) {
        self.circleId = circleId
        self.ownerUserId = ownerUserId
    }

    // MARK: - Lifecycle

    func startLive(tracker: LocationTracker) {
        tracker.setActiveCircleId(circleId)
        tracker.setLiveMapActive(true)

        // Subscribe for silent-push driven updates.
        cloudKit.subscribeToLocations(circleId: circleId)

        // Seed immediately then start the safety-net poll loop.
        pollTask = Task { [weak self] in
            guard let self else { return }
            await self.refreshFriendLocations()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self.pollIntervalSeconds))
                guard !Task.isCancelled else { break }
                await self.refreshFriendLocations()
            }
        }
    }

    func stopLive(tracker: LocationTracker) {
        pollTask?.cancel()
        pollTask = nil
        tracker.setLiveMapActive(false)
    }

    // MARK: - Data

    func refreshFriendLocations() async {
        await withCheckedContinuation { continuation in
            cloudKit.fetchCircleMemberLocations(circleId: circleId) { [weak self] result in
                Task { @MainActor [weak self] in
                    guard let self else { continuation.resume(); return }
                    switch result {
                    case .success(let pins):
                        self.friendPins = pins.filter { $0.id != self.ownerUserId }
                        self.fetchError = nil
                    case .failure(let error):
                        self.fetchError = error.localizedDescription
                    }
                    continuation.resume()
                }
            }
        }
    }
}
