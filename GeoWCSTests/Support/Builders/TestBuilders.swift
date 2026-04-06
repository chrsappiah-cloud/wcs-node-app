import Foundation

enum TestIDs {
    static func make(prefix: String = "id", index: Int = 1) -> String {
        "\(prefix)-\(index)"
    }
}

enum TestDates {
    static func fixed(
        year: Int = 2026,
        month: Int = 1,
        day: Int = 1,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0
    ) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        return components.date ?? Date(timeIntervalSince1970: 0)
    }
}

enum TestURLs {
    static func make(_ path: String = "/resource") -> URL {
        URL(string: "https://example.test\(path)")!
    }
}