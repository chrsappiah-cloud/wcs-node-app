import Foundation

enum FixtureLoader {
    enum FixtureError: Error, LocalizedError {
        case fileNotFound(String)
        case failedToRead(String)
        case failedToDecode(String)

        var errorDescription: String? {
            switch self {
            case .fileNotFound(let name):
                return "Fixture not found: \(name)"
            case .failedToRead(let name):
                return "Could not read fixture: \(name)"
            case .failedToDecode(let name):
                return "Could not decode fixture: \(name)"
            }
        }
    }

    static func data(named name: String, bundle: Bundle = .testBundle) throws -> Data {
        guard let url = bundle.url(forResource: name, withExtension: nil) else {
            throw FixtureError.fileNotFound(name)
        }
        guard let data = try? Data(contentsOf: url) else {
            throw FixtureError.failedToRead(name)
        }
        return data
    }

    static func decode<T: Decodable>(
        _ type: T.Type,
        named name: String,
        decoder: JSONDecoder = JSONDecoder(),
        bundle: Bundle = .testBundle
    ) throws -> T {
        let raw = try data(named: name, bundle: bundle)
        guard let decoded = try? decoder.decode(T.self, from: raw) else {
            throw FixtureError.failedToDecode(name)
        }
        return decoded
    }
}

private extension Bundle {
    static var testBundle: Bundle {
        Bundle(for: TestBundleSentinel.self)
    }
}

private final class TestBundleSentinel {}