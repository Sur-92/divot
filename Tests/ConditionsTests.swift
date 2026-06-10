import XCTest

final class ConditionsTests: XCTestCase {
    func testRoundTrip() throws {
        var c = NineConditions()
        c.greenSpeed = 6; c.tees = 1; c.pace = 3; c.solo = true; c.tired = true
        let data = try JSONEncoder().encode(c)
        let back = try JSONDecoder().decode(NineConditions.self, from: data)
        XCTAssertEqual(c, back)
    }

    func testEmpty() {
        XCTAssertTrue(NineConditions().isEmpty)
        var c = NineConditions(); c.anxiety = 2
        XCTAssertFalse(c.isEmpty)
    }

    /// The whole point of JSON storage: adding a field must not break old
    /// rounds. JSON written before `tees`/`roughPaths` existed must decode
    /// with those fields defaulted — NOT throw and reset everything.
    func testMissingFieldsDecodeToDefaults() throws {
        let old = #"{"greenSpeed":3,"pace":2,"solo":true}"#
        let c = try JSONDecoder().decode(NineConditions.self, from: Data(old.utf8))
        XCTAssertEqual(c.greenSpeed, 3)
        XCTAssertEqual(c.pace, 2)
        XCTAssertTrue(c.solo)
        XCTAssertEqual(c.tees, 0)        // newer field → default, not a failure
        XCTAssertFalse(c.roughPaths)     // newer field → default
    }

    /// A single type-mismatched field shouldn't nuke the whole struct.
    func testGarbageFieldTolerated() throws {
        let mixed = #"{"greenSpeed":4,"solo":"yes","tees":2}"#
        let c = try JSONDecoder().decode(NineConditions.self, from: Data(mixed.utf8))
        XCTAssertEqual(c.greenSpeed, 4)
        XCTAssertEqual(c.tees, 2)
        XCTAssertFalse(c.solo)           // "yes" isn't a Bool → default, not a throw
    }
}
