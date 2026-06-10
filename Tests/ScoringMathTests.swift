import XCTest

/// Pure WHS math — no SwiftData, no container. This is the high-value
/// logic (the handicap "headline number") and it's now testable directly.
final class ScoringMathTests: XCTestCase {

    func testAdjustedGrossCapsAtNetDoubleBogey() {
        // par 4: a 10 caps to 6; a 5 and a 4 pass through unchanged.
        XCTAssertEqual(ScoringMath.adjustedGross(pars: [4, 4, 4], scores: [4, 5, 10]),
                       4 + 5 + 6)
    }

    func testEighteenHoleDifferential() {
        // 18× par-4 (par 72) scored 5 = 90; 5 ≤ par+2 so nothing caps.
        let adj = ScoringMath.adjustedGross(pars: Array(repeating: 4, count: 18),
                                            scores: Array(repeating: 5, count: 18))
        XCTAssertEqual(adj, 90)
        // (113/113) × (90 − 72) = 18.0
        XCTAssertEqual(ScoringMath.differential(adjustedGross: adj, rating: 72, slope: 113),
                       18.0, accuracy: 0.001)
    }

    func testNetDoubleBogeyCapInDifferential() {
        // 17× 4 then one blow-up 10 on a par 4 → capped at 6.
        let adj = ScoringMath.adjustedGross(
            pars: Array(repeating: 4, count: 18),
            scores: Array(repeating: 4, count: 17) + [10])
        XCTAssertEqual(adj, 17 * 4 + 6)   // 74
        // (113/113) × (74 − 72) = 2.0
        XCTAssertEqual(ScoringMath.differential(adjustedGross: adj, rating: 72, slope: 113),
                       2.0, accuracy: 0.001)
    }

    func testNineHoleHalvedRating() {
        // 9× par-4 scored 5 = 45 ; 9-hole rating = 72/2 = 36 ; slope 113.
        let adj = ScoringMath.adjustedGross(pars: Array(repeating: 4, count: 9),
                                            scores: Array(repeating: 5, count: 9))
        XCTAssertEqual(adj, 45)
        XCTAssertEqual(ScoringMath.differential(adjustedGross: adj, rating: 36, slope: 113),
                       9.0, accuracy: 0.001)
    }

    func testSlopeZeroYieldsZero() {
        // Unrated tee → no differential (caller treats as out-of-pool).
        XCTAssertEqual(ScoringMath.differential(adjustedGross: 90, rating: 72, slope: 0), 0)
    }

    func testPer9Equivalence() {
        XCTAssertEqual(ScoringMath.per9(45, holeCount: 9), 45, accuracy: 0.001)
        XCTAssertEqual(ScoringMath.per9(90, holeCount: 18), 45, accuracy: 0.001)
        XCTAssertEqual(ScoringMath.per9(45, holeCount: 9),
                       ScoringMath.per9(90, holeCount: 18), accuracy: 0.001)
        XCTAssertEqual(ScoringMath.per9(10, holeCount: 0), 0)   // guard
    }
}
