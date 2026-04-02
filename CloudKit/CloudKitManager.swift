import Foundation
import CloudKit

final class CloudKitManager {
    private let container: CKContainer
    private let database: CKDatabase

    init() {
        if let identifier = Bundle.main.object(forInfoDictionaryKey: "CloudKitContainerIdentifier") as? String,
           !identifier.isEmpty {
            container = CKContainer(identifier: identifier)
        } else {
            container = CKContainer.default()
        }

        let scope = (Bundle.main.object(forInfoDictionaryKey: "CloudKitDatabaseScope") as? String)?.lowercased()
        database = scope == "private" ? container.privateCloudDatabase : container.publicCloudDatabase
    }

    func subscribeToLocations(circleId: String) {
        let predicate = NSPredicate(format: "%K == %@", CloudKitField.circleId, circleId)
        let subscription = CKQuerySubscription(
            recordType: CloudKitRecordType.locationEvent,
            predicate: predicate,
            subscriptionID: "locations-\(circleId)",
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo

        database.save(subscription) { _, error in
            if let error = error {
                print("Subscription error: \(error)")
            } else {
                print("Subscribed to LocationEvent updates for circleId: \(circleId)")
            }
        }
    }

    func saveLocation(_ location: LocationRecord, circleId: String?, completion: @escaping (Result<CKRecord.ID, Error>) -> Void) {
        let record = CKRecord(recordType: CloudKitRecordType.locationEvent)
        record[CloudKitField.userId] = location.userId as CKRecordValue
        record[CloudKitField.lat] = location.lat as CKRecordValue
        record[CloudKitField.lng] = location.lng as CKRecordValue
        record[CloudKitField.timestamp] = location.timestamp as CKRecordValue
        record[CloudKitField.accuracy] = location.accuracy as CKRecordValue
        record[CloudKitField.speedKmh] = location.speedKmh as CKRecordValue
        record[CloudKitField.heading] = location.heading as CKRecordValue

        if let circleId {
            record[CloudKitField.circleId] = circleId as CKRecordValue
        }

        database.save(record) { savedRecord, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let savedRecord else {
                completion(.failure(NSError(domain: "CloudKitManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Save returned no record"])))
                return
            }

            completion(.success(savedRecord.recordID))
        }
    }

    func saveCircle(_ circle: CircleRecord, completion: @escaping (Result<CKRecord.ID, Error>) -> Void) {
        let record = CKRecord(recordType: CloudKitRecordType.circle)
        record[CloudKitField.name] = circle.name as CKRecordValue
        record[CloudKitField.members] = circle.members as CKRecordValue
        record[CloudKitField.ownerId] = circle.ownerId as CKRecordValue

        database.save(record) { savedRecord, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let savedRecord else {
                completion(.failure(NSError(domain: "CloudKitManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Save returned no record"])))
                return
            }
            completion(.success(savedRecord.recordID))
        }
    }

    func saveCircleSnapshot(
        recordID: CKRecord.ID?,
        circle: CircleRecord,
        completion: @escaping (Result<CircleSnapshot, Error>) -> Void
    ) {
        let record = recordID.map { CKRecord(recordType: CloudKitRecordType.circle, recordID: $0) }
            ?? CKRecord(recordType: CloudKitRecordType.circle)

        record[CloudKitField.name] = circle.name as CKRecordValue
        record[CloudKitField.members] = circle.members as CKRecordValue
        record[CloudKitField.ownerId] = circle.ownerId as CKRecordValue

        database.save(record) { savedRecord, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let savedRecord else {
                completion(
                    .failure(
                        NSError(
                            domain: "CloudKitManager",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Save returned no record"]
                        )
                    )
                )
                return
            }

            let snapshot = CircleSnapshot(
                id: savedRecord.recordID.recordName,
                name: (savedRecord[CloudKitField.name] as? String) ?? circle.name,
                members: (savedRecord[CloudKitField.members] as? [String]) ?? circle.members,
                ownerId: (savedRecord[CloudKitField.ownerId] as? String) ?? circle.ownerId
            )
            completion(.success(snapshot))
        }
    }

    func fetchCircles(ownerId: String, completion: @escaping (Result<[CircleSnapshot], Error>) -> Void) {
        let predicate = NSPredicate(format: "%K == %@", CloudKitField.ownerId, ownerId)
        let query = CKQuery(recordType: CloudKitRecordType.circle, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: CloudKitField.timestamp, ascending: false)]

        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 25

        var circles: [CircleSnapshot] = []
        operation.recordMatchedBlock = { _, result in
            if case .success(let record) = result {
                circles.append(
                    CircleSnapshot(
                        id: record.recordID.recordName,
                        name: (record[CloudKitField.name] as? String) ?? "Unnamed Circle",
                        members: (record[CloudKitField.members] as? [String]) ?? [],
                        ownerId: (record[CloudKitField.ownerId] as? String) ?? ownerId
                    )
                )
            }
        }

        operation.queryResultBlock = { result in
            switch result {
            case .success:
                completion(.success(circles))
            case .failure(let error):
                completion(.failure(error))
            }
        }

        database.add(operation)
    }

    func saveGeofence(_ geofence: GeofenceRecord, completion: @escaping (Result<CKRecord.ID, Error>) -> Void) {
        let record = CKRecord(recordType: CloudKitRecordType.geofence)
        record[CloudKitField.lat] = geofence.centerLat as CKRecordValue
        record[CloudKitField.lng] = geofence.centerLng as CKRecordValue
        record[CloudKitField.radius] = geofence.radius as CKRecordValue
        record[CloudKitField.circleId] = geofence.circleId as CKRecordValue

        database.save(record) { savedRecord, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let savedRecord else {
                completion(.failure(NSError(domain: "CloudKitManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Save returned no record"])))
                return
            }
            completion(.success(savedRecord.recordID))
        }
    }

    func fetchRecentLocations(userId: String, limit: Int = 25, completion: @escaping (Result<[CKRecord], Error>) -> Void) {
        let predicate = NSPredicate(format: "%K == %@", CloudKitField.userId, userId)
        let query = CKQuery(recordType: CloudKitRecordType.locationEvent, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: CloudKitField.timestamp, ascending: false)]

        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = max(1, min(limit, 100))

        var records: [CKRecord] = []
        operation.recordMatchedBlock = { _, result in
            if case .success(let record) = result {
                records.append(record)
            }
        }

        operation.queryResultBlock = { result in
            switch result {
            case .success:
                completion(.success(records))
            case .failure(let error):
                completion(.failure(error))
            }
        }

        database.add(operation)
    }

    /// Fetches the most-recent `LocationEvent` record for every member in the
    /// given circle, returning one `FriendPin` per unique `userId`.
    /// Results are sorted newest-first server-side; duplicates (older records
    /// for the same user) are discarded client-side.
    func fetchCircleMemberLocations(
        circleId: String,
        completion: @escaping (Result<[FriendPin], Error>) -> Void
    ) {
        let predicate = NSPredicate(format: "%K == %@", CloudKitField.circleId, circleId)
        let query = CKQuery(recordType: CloudKitRecordType.locationEvent, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: CloudKitField.timestamp, ascending: false)]

        let operation = CKQueryOperation(query: query)
        // Fetch enough records to guarantee one hit per member even in large circles.
        operation.resultsLimit = 200

        var seen = Set<String>()
        var pins: [FriendPin] = []

        operation.recordMatchedBlock = { _, result in
            guard case .success(let record) = result else { return }
            let userId = (record[CloudKitField.userId] as? String) ?? "unknown"
            guard seen.insert(userId).inserted else { return }

            let lat      = (record[CloudKitField.lat]      as? Double) ?? 0
            let lng      = (record[CloudKitField.lng]      as? Double) ?? 0
            let heading  = (record[CloudKitField.heading]  as? Double) ?? -1
            let speed    = (record[CloudKitField.speedKmh] as? Double) ?? 0
            let accuracy = (record[CloudKitField.accuracy] as? Double) ?? 0
            let ts       = (record[CloudKitField.timestamp] as? Date)  ?? Date()

            pins.append(FriendPin(
                id: userId,
                displayName: String(userId.prefix(8)),
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                heading: heading,
                speedKmh: speed,
                accuracy: max(accuracy, 1),
                updatedAt: ts
            ))
        }

        operation.queryResultBlock = { result in
            switch result {
            case .success:
                completion(.success(pins))
            case .failure(let error):
                completion(.failure(error))
            }
        }

        database.add(operation)
    }

    func saveSOSIncident(_ incident: SOSIncidentRecord, completion: @escaping (Result<CKRecord.ID, Error>) -> Void) {
        let record = CKRecord(recordType: CloudKitRecordType.sosIncident)
        record[CloudKitField.userId] = incident.userId as CKRecordValue
        record[CloudKitField.contacts] = incident.contacts as CKRecordValue
        record[CloudKitField.message] = incident.message as CKRecordValue
        record[CloudKitField.status] = incident.status as CKRecordValue
        record[CloudKitField.timestamp] = incident.timestamp as CKRecordValue
        if let lat = incident.lat {
            record[CloudKitField.lat] = lat as CKRecordValue
        }
        if let lng = incident.lng {
            record[CloudKitField.lng] = lng as CKRecordValue
        }

        database.save(record) { savedRecord, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let savedRecord else {
                completion(
                    .failure(
                        NSError(
                            domain: "CloudKitManager",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Save returned no record"]
                        )
                    )
                )
                return
            }

            completion(.success(savedRecord.recordID))
        }
    }
}
