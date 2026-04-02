import Foundation

// MARK: - Auth Method

enum AuthMethod: String, Codable {
    case phone
    case apple
    case google
}

// MARK: - Subscription Tier

enum SubscriptionTier: String, Codable {
    /// Default tier — limited circles, history, no live map for friends.
    case free
    /// Paid tier — unlimited circles, full live map, extended history.
    case premium
}

// MARK: - Auth Session

/// Identifies the current signed-in user across app launches.
/// Persisted to the Keychain via `AuthManager`.
struct AuthSession: Codable, Equatable {
    /// Stable identifier: E.164 number, Apple user sub, or Google sub.
    let userId: String
    let authMethod: AuthMethod
    /// Displayed in the UI and on map pins.
    var displayName: String
    var phoneNumber: String?
    var email: String?
    /// JWT issued by the GeoWCS backend after successful sign-in.
    var bearerToken: String
    /// Explicit consent timestamp — must be set before any location sharing.
    var consentGrantedAt: Date?
    var tier: SubscriptionTier
}

// MARK: - Tier limits

extension SubscriptionTier {
    var maxCircles: Int { self == .premium ? Int.max : 2 }
    var locationHistoryDays: Int { self == .premium ? 30 : 3 }
    var liveMapEnabled: Bool { self == .premium }
}
