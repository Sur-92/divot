import XCTest
import SwiftData

/// Covers the WHS differential math, per-9 normalization, and the round-pool
/// eligibility policy. Uses an in-memory SwiftData store so Round/Hole behave
/// exactly as in the app.
final class HandicapMathTests: XCTestCase {

    @MainActor
    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Round.self, Hole.self, Shot.self,
                 Course.self, CourseHole.self, CourseTee.self,
            configurations: config)
        return container.mainContext
    }

    @MainActor
    private func makeRound(_ ctx: ModelContext, holes n: Int, par: Int, score: Int,
                           slope: Int, rating: Double) -> Round {
        let r = Round(date: Date(timeIntervalSince1970: 0), courseName: "Test",
                      tees: "White", courseRating: rating, slopeRating: slope)
        ctx.insert(r)
        // Same wiring as StartRoundSheet: set the inverse + append; the
        // relationship graph carries the holes into the context.
        for i in 1...n {
            let h = Hole(number: i, par: par, score: score)
            h.round = r
            r.holes.append(h)
        }
        return r
    }

    @MainActor
    func testEighteenHoleDifferential() throws {
        let ctx = try makeContext()
        // 18× par-4 (par 72) scored 5 each = 90; 5 ≤ par+2 so no cap.
        let r = makeRound(ctx, holes: 18, par: 4, score: 5, slope: 113, rating: 72.0)
        XCTAssertEqual(r.totalScore, 90)
        // (113/113) × (90 − 72) = 18.0
        XCTAssertEqual(r.scoreDifferential, 18.0, accuracy: 0.001)
    }

    @MainActor
    func testNetDoubleBogeyCap() throws {
        let ctx = try makeContext()
        let r = makeRound(ctx, holes: 18, par: 4, score: 4, slope: 113, rating: 72.0)
        // Blow up one hole to 10 — should cap at par+2 = 6.
        r.holes.first(where: { $0.number == 18 })?.score = 10
        // adjusted = 17×4 + 6 = 74 ; (113/113) × (74 − 72) = 2.0
        XCTAssertEqual(r.scoreDifferential, 2.0, accuracy: 0.001)
    }

    @MainActor
    func testNineHoleHalvesRating() throws {
        let ctx = try makeContext()
        // 9× par-4 (par 36) scored 5 = 45 ; rating halved 72→36 ; slope 113.
        let r = makeRound(ctx, holes: 9, par: 4, score: 5, slope: 113, rating: 72.0)
        XCTAssertEqual(r.holeCount, 9)
        // (113/113) × (45 − 36) = 9.0
        XCTAssertEqual(r.scoreDifferential, 9.0, accuracy: 0.001)
    }

    @MainActor
    func testPer9NormalizationEquivalence() throws {
        let ctx = try makeContext()
        let nine = makeRound(ctx, holes: 9, par: 4, score: 5, slope: 113, rating: 72)
        let eighteen = makeRound(ctx, holes: 18, par: 4, score: 5, slope: 113, rating: 72)
        // A 45-on-9 and a 90-on-18 both normalize to 45 per 9.
        XCTAssertEqual(nine.scorePer9, 45, accuracy: 0.001)
        XCTAssertEqual(nine.scorePer9, eighteen.scorePer9, accuracy: 0.001)
    }

    // MARK: - Eligibility policy (the rules Stats/Handicap share)

    @MainActor
    func testSlopeZeroExcludedFromHandicap() throws {
        let ctx = try makeContext()
        let r = makeRound(ctx, holes: 18, par: 4, score: 5, slope: 0, rating: 72)
        XCTAssertFalse(r.isHandicapEligible)   // slope 0 would give a fake 0.0 diff
    }

    @MainActor
    func testParThreeCourseExcluded() throws {
        let ctx = try makeContext()
        let par3 = makeRound(ctx, holes: 18, par: 3, score: 4, slope: 100, rating: 54)
        XCTAssertTrue(par3.isParThreeCourse)
        XCTAssertFalse(par3.isHandicapEligible)
        XCTAssertFalse(par3.isStatsEligible)

        let reg = makeRound(ctx, holes: 18, par: 4, score: 5, slope: 113, rating: 72)
        XCTAssertFalse(reg.isParThreeCourse)
        XCTAssertTrue(reg.isHandicapEligible)
        XCTAssertTrue(reg.isStatsEligible)
    }

    @MainActor
    func testReconstructedExcludedFromStatsButNotHandicap() throws {
        let ctx = try makeContext()
        let r = makeRound(ctx, holes: 18, par: 4, score: 5, slope: 113, rating: 72)
        r.isReconstructed = true
        XCTAssertFalse(r.isStatsEligible)      // synthetic per-hole detail
        XCTAssertTrue(r.isScoringEligible)     // totals are accurate
        XCTAssertTrue(r.isHandicapEligible)    // capped scores → valid differential
    }
}
