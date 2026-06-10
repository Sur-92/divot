import XCTest

/// The data-honesty policy that Stats and Handicap share (Round.is*Eligible).
/// Builds Round + Hole objects WITHOUT a SwiftData container — bare @Model
/// instances are valid for reading computed properties; only ModelContainer
/// creation was the CI-fragile part.
final class EligibilityTests: XCTestCase {

    private func round(holeCount: Int, par: Int, score: Int, slope: Int) -> Round {
        let r = Round(courseName: "Test", tees: "White",
                      courseRating: 70, slopeRating: slope)
        for i in 1...holeCount {
            let h = Hole(number: i, par: par, score: score)
            h.round = r
            r.holes.append(h)
        }
        return r
    }

    func testParThreeCourseExcluded() {
        let p3 = round(holeCount: 18, par: 3, score: 4, slope: 100)
        XCTAssertTrue(p3.isParThreeCourse)
        XCTAssertFalse(p3.isHandicapEligible)
        XCTAssertFalse(p3.isStatsEligible)
    }

    func testRegulationRoundEligible() {
        let r = round(holeCount: 18, par: 4, score: 5, slope: 113)
        XCTAssertFalse(r.isParThreeCourse)
        XCTAssertTrue(r.isScoringEligible)
        XCTAssertTrue(r.isStatsEligible)
        XCTAssertTrue(r.isHandicapEligible)
    }

    func testSlopeZeroExcludedFromHandicap() {
        let r = round(holeCount: 18, par: 4, score: 5, slope: 0)
        XCTAssertFalse(r.isHandicapEligible)   // unrated tee → fake 0.0 diff avoided
    }

    func testReconstructedExcludedFromStatsButNotHandicap() {
        let r = round(holeCount: 18, par: 4, score: 5, slope: 113)
        r.isReconstructed = true
        XCTAssertFalse(r.isStatsEligible)      // synthetic per-hole detail
        XCTAssertTrue(r.isScoringEligible)     // totals accurate
        XCTAssertTrue(r.isHandicapEligible)    // capped scores → valid differential
    }

    func testArchivedExcludedEverywhere() {
        let r = round(holeCount: 18, par: 4, score: 5, slope: 113)
        r.isArchived = true
        XCTAssertFalse(r.isScoringEligible)
        XCTAssertFalse(r.isStatsEligible)
        XCTAssertFalse(r.isHandicapEligible)
    }
}
