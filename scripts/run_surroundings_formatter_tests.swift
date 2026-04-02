import Foundation

// Standalone contract tests for the surroundings text composition rules.
struct SurroundingsFormatterContract {
    static func format(components: [String?], fallbackName: String?) -> String {
        let normalized = components.compactMap { value -> String? in
            guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
                return nil
            }
            return trimmed
        }

        var seen = Set<String>()
        let uniqueComponents = normalized.filter { seen.insert($0).inserted }

        if uniqueComponents.isEmpty {
            if let fallback = fallbackName?.trimmingCharacters(in: .whitespacesAndNewlines), !fallback.isEmpty {
                return fallback
            }
            return "Nearby area"
        }

        return uniqueComponents.joined(separator: ", ")
    }
}

struct TestCase {
    let name: String
    let components: [String?]
    let fallbackName: String?
    let expected: String
}

let tests: [TestCase] = [
    TestCase(
        name: "Uses ordered components",
        components: ["Downtown", "Accra", nil, "Greater Accra", "Ghana"],
        fallbackName: nil,
        expected: "Downtown, Accra, Greater Accra, Ghana"
    ),
    TestCase(
        name: "Trims and removes empties",
        components: ["  Airport West  ", "", "   ", nil, "Ghana"],
        fallbackName: nil,
        expected: "Airport West, Ghana"
    ),
    TestCase(
        name: "Deduplicates repeated fields",
        components: ["Accra", "Accra", nil, "Accra", "Ghana"],
        fallbackName: nil,
        expected: "Accra, Ghana"
    ),
    TestCase(
        name: "Falls back to name when components empty",
        components: [nil, "", "   ", nil, nil],
        fallbackName: "Kotoka Intl Airport",
        expected: "Kotoka Intl Airport"
    ),
    TestCase(
        name: "Falls back to Nearby area when everything empty",
        components: [nil, "", "   ", nil, nil],
        fallbackName: "",
        expected: "Nearby area"
    )
]

var failures = 0
for test in tests {
    let actual = SurroundingsFormatterContract.format(components: test.components, fallbackName: test.fallbackName)
    if actual != test.expected {
        failures += 1
        print("FAIL: \(test.name)")
        print("  expected: \(test.expected)")
        print("  actual:   \(actual)")
    } else {
        print("PASS: \(test.name)")
    }
}

if failures > 0 {
    print("\n\(failures) test(s) failed")
    exit(1)
}

print("\nAll \(tests.count) surroundings formatter tests passed")
