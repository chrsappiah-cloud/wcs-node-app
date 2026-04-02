import Foundation

enum CloudKitRecordType {
    static let locationEvent = "LocationEvent"
    static let geofence = "Geofence"
    static let circle = "Circle"
    static let sosIncident = "SOSIncident"
}

enum CloudKitField {
    static let userId = "userId"
    static let circleId = "circleId"
    static let geofenceId = "geofenceId"
    static let lat = "lat"
    static let lng = "lng"
    static let radius = "radius"
    static let name = "name"
    static let ownerId = "ownerId"
    static let members = "members"
    static let timestamp = "timestamp"
    static let accuracy = "accuracy"
    static let speedKmh = "speedKmh"
    static let heading = "heading"
    static let contacts = "contacts"
    static let message = "message"
    static let status = "status"
}

struct LocationRecord {
    let lat: Double
    let lng: Double
    let timestamp: Date
    let userId: String
    let accuracy: Double
    let speedKmh: Double
    let heading: Double
}

struct GeofenceRecord {
    let centerLat: Double
    let centerLng: Double
    let radius: Double
    let circleId: String
}

struct CircleRecord {
    let name: String
    let members: [String]
    let ownerId: String
}

struct CircleSnapshot: Identifiable {
    let id: String
    let name: String
    let members: [String]
    let ownerId: String
}

struct SOSIncidentRecord {
    let userId: String
    let contacts: [String]
    let message: String
    let status: String
    let timestamp: Date
    let lat: Double?
    let lng: Double?
}
