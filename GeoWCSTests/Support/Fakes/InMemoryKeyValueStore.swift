import Foundation

protocol KeyValueStoring {
    func data(forKey key: String) -> Data?
    func set(_ value: Data?, forKey key: String)
    func removeObject(forKey key: String)
}

final class InMemoryKeyValueStore: KeyValueStoring {
    private var storage: [String: Data] = [:]

    func data(forKey key: String) -> Data? {
        storage[key]
    }

    func set(_ value: Data?, forKey key: String) {
        storage[key] = value
    }

    func removeObject(forKey key: String) {
        storage.removeValue(forKey: key)
    }

    func reset() {
        storage.removeAll()
    }
}