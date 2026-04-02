import Foundation
import CoreLocation

/// A single friend's most-recent known position on the live map.
struct FriendPin: Identifiable, Equatable {
    /// Stable identity — matches the CloudKit `userId` field.
    let id: String
    /// Short display name shown on the map annotation.
    var displayName: String
    var coordinate: CLLocationCoordinate2D
    /// GPS course in degrees (0 = north, –1 = unavailable).
    var heading: Double
    var speedKmh: Double
    /// Horizontal accuracy in metres — used to draw the accuracy halo.
    var accuracy: Double
    var updatedAt: Date

    /// Returns true when the last update is older than two minutes.
    var isStale: Bool {
        Date().timeIntervalSince(updatedAt) > 120
    }

    static func == (lhs: FriendPin, rhs: FriendPin) -> Bool {
        lhs.id == rhs.id
            && lhs.coordinate.latitude == rhs.coordinate.latitude
            && lhs.coordinate.longitude == rhs.coordinate.longitude
            && lhs.updatedAt == rhs.updatedAt
    }
}
