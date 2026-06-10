import XCTest

final class ScoreFormattingTests: XCTestCase {
    func testToParText() {
        XCTAssertEqual((-3).toParText, "-3")
        XCTAssertEqual((-1).toParText, "-1")
        XCTAssertEqual(0.toParText, "E")     // even par is "E", never "+0"
        XCTAssertEqual(1.toParText, "+1")
        XCTAssertEqual(18.toParText, "+18")
    }
}
