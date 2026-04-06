import XCTest

final class TestSupportUtilitiesTests: XCTestCase {

    private struct SampleProfile: Decodable, Equatable {
        let name: String
        let stepCount: Int
        let isCalmVoice: Bool
    }

    func testCallSpyRecordsAndCountsCalls() {
        let spy = CallSpy()
        spy.record("save")
        spy.record("save")
        spy.record("fetch")

        XCTAssertTrue(spy.wasCalled("save"))
        XCTAssertTrue(spy.wasCalled("fetch"))
        XCTAssertEqual(spy.callCount(for: "save"), 2)
        XCTAssertEqual(spy.callCount(for: "fetch"), 1)
    }

    func testInMemoryKeyValueStoreStoresAndRemovesData() {
        let store = InMemoryKeyValueStore()
        let key = "asset"
        let payload = Data("hello".utf8)

        store.set(payload, forKey: key)
        XCTAssertEqual(store.data(forKey: key), payload)

        store.removeObject(forKey: key)
        XCTAssertNil(store.data(forKey: key))
    }

    func testTestIDsBuilderProducesStableID() {
        XCTAssertEqual(TestIDs.make(prefix: "carer", index: 7), "carer-7")
    }

    func testTestDatesBuilderProducesExpectedUTCComponents() {
        let date = TestDates.fixed(year: 2026, month: 4, day: 4, hour: 12, minute: 30, second: 0)
        let calendar = Calendar(identifier: .gregorian)
        let comps = calendar.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: date)

        XCTAssertEqual(comps.year, 2026)
        XCTAssertEqual(comps.month, 4)
        XCTAssertEqual(comps.day, 4)
        XCTAssertEqual(comps.hour, 12)
        XCTAssertEqual(comps.minute, 30)
        XCTAssertEqual(comps.second, 0)
    }

    func testTestURLsBuilderUsesExampleDomain() {
        XCTAssertEqual(TestURLs.make("/v1/items").absoluteString, "https://example.test/v1/items")
    }

    func testFixtureLoaderReturnsFileNotFoundForMissingFixture() {
        XCTAssertThrowsError(try FixtureLoader.data(named: "missing.json")) { error in
            guard case FixtureLoader.FixtureError.fileNotFound(let name) = error else {
                return XCTFail("Expected fileNotFound, got \(error)")
            }
            XCTAssertEqual(name, "missing.json")
        }
    }

    func testFixtureLoaderDecodesSampleProfileFixture() throws {
        let decoded = try FixtureLoader.decode(SampleProfile.self, named: "sample_profile.json")

        XCTAssertEqual(
            decoded,
            SampleProfile(name: "Morning Session", stepCount: 3, isCalmVoice: true)
        )
    }
}