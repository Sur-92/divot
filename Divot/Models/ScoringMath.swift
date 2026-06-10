import Foundation

/// Pure scoring / handicap math, extracted from `Round` so the WHS logic is
/// unit-testable on plain values — no SwiftData container required (creating
/// one in the test runner proved fragile). `Round` delegates to these.
enum ScoringMath {

    /// Adjusted gross: each hole capped at net double bogey (par + 2).
    /// `pars` and `scores` are parallel, one entry per hole played.
    static func adjustedGross(pars: [Int], scores: [Int]) -> Int {
        zip(pars, scores).reduce(0) { total, hole in
            let (par, score) = hole
            return total + min(score, par + 2)
        }
    }

    /// WHS score differential = (113 / slope) × (adjusted gross − rating).
    /// `rating` must already be the applicable rating (halved for a 9-hole
    /// round). Returns 0 for a non-positive slope (an unrated tee), which
    /// callers treat as "not in the pool."
    static func differential(adjustedGross: Int, rating: Double, slope: Int) -> Double {
        guard slope > 0 else { return 0 }
        return (113.0 / Double(slope)) * (Double(adjustedGross) - rating)
    }

    /// Normalize a count (strokes, or strokes-to-par) to a per-9-hole basis
    /// so 9- and 18-hole rounds compare fairly. A 45-on-9 and a 90-on-18
    /// both return 45.
    static func per9(_ value: Int, holeCount: Int) -> Double {
        guard holeCount > 0 else { return 0 }
        return Double(value) / Double(holeCount) * 9
    }
}
