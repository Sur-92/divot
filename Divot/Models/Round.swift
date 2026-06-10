import Foundation
import SwiftData

// MARK: - Round type

enum RoundType: String, CaseIterable, Codable, Hashable, Identifiable {
    case full18
    case front9
    case back9

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .full18: return "18 Holes"
        case .front9: return "Front 9"
        case .back9:  return "Back 9"
        }
    }

    var shortBadge: String {
        switch self {
        case .full18: return "18"
        case .front9: return "F9"
        case .back9:  return "B9"
        }
    }

    var holeCount: Int { self == .full18 ? 18 : 9 }

    /// Range of course-hole numbers (1-indexed) covered by this round.
    var holeRange: ClosedRange<Int> {
        switch self {
        case .full18: return 1...18
        case .front9: return 1...9
        case .back9:  return 10...18
        }
    }
}

@Model
final class Round {
    var date: Date
    var courseName: String
    var tees: String
    var courseRating: Double
    var slopeRating: Int
    var notes: String

    /// Raw persisted value for roundType. Using a String column keeps
    /// SwiftData's lightweight migrations happy with existing rows
    /// (NULL on old rows is treated as "full18" by the computed getter).
    var roundTypeRaw: String = RoundType.full18.rawValue

    /// Full 18, front 9, or back 9. Existing rounds default to .full18.
    var roundType: RoundType {
        get { RoundType(rawValue: roundTypeRaw) ?? .full18 }
        set { roundTypeRaw = newValue.rawValue }
    }

    /// Stable identity across sync, backup, and replay boundaries.
    /// Generated on insert, never changes. Enables replay-safe writes
    /// if/when an audit or sync layer is added later.
    var idempotencyKey: String = ""

    /// Soft-delete flag. Archived rounds are hidden from the main Rounds list,
    /// Stats, and Handicap, but the data is preserved — user can restore or
    /// fully delete from the Archived view.
    var isArchived: Bool = false

    /// Marks rounds whose hole-by-hole data is partial or estimated — e.g.
    /// rounds reconstructed from old screenshots where the totals are
    /// known but individual hole scores had to be synthesized. STATS
    /// excludes these (their FIR/GIR/putts are synthetic), but HANDICAP
    /// INCLUDES them: the totals are accurate and the synthetic per-hole
    /// scores are capped at par+2, exactly the net-double-bogey ceiling the
    /// differential uses, so the differential stays valid. The round shows
    /// on the main Rounds list with a small badge.
    var isReconstructed: Bool = false

    /// When the parent course is an indoor simulator (`Course.isSimulator`),
    /// this records which actual course was loaded on the sim that day —
    /// e.g. "Pebble Beach", "Augusta", "Bandon Trails". Empty for outdoor
    /// rounds. Existing rows migrate to "" cleanly.
    var simulatedCourseName: String = ""

    /// Cached historical weather for the round's date + course location,
    /// fetched once from Open-Meteo (a past date's weather never changes).
    /// `weatherCode` is the WMO code; -1 means "not fetched yet".
    var weatherCode: Int = -1
    var weatherHighF: Double = 0
    var weatherLowF: Double = 0
    var weatherWindMph: Double = 0
    var weatherPrecipIn: Double = 0

    var hasWeather: Bool { weatherCode >= 0 }

    /// Front-9 tee time as minutes from midnight (local); -1 = unset.
    /// Figuring ~2 hours per nine, the back nine is sampled ≈ +2h later.
    var teeTimeMinutes: Int = -1

    /// Per-nine conditions sampled mid-nine when a tee time is set
    /// (frontCode/backCode == -1 means not sampled).
    var frontCode: Int = -1
    var frontTempF: Double = 0
    var frontWindMph: Double = 0
    var backCode: Int = -1
    var backTempF: Double = 0
    var backWindMph: Double = 0

    var hasTeeTime: Bool { teeTimeMinutes >= 0 }
    var hasNineWeather: Bool { frontCode >= 0 }

    /// Total balls lost during the round.
    var lostBalls: Int = 0

    /// Per-nine conditions (course surface, situation, player state), stored
    /// as JSON. TEXT column → SQLite-safe and tolerant of schema growth.
    /// Empty string decodes to all-defaults.
    var frontConditions: String = ""
    var backConditions: String = ""

    /// Decoded views of the conditions JSON. Reading/writing these round-trips
    /// through the stored String, so SwiftData observes the change and saves.
    var frontConditionsValue: NineConditions {
        get { Self.decodeConditions(frontConditions) }
        set { frontConditions = Self.encodeConditions(newValue) }
    }
    var backConditionsValue: NineConditions {
        get { Self.decodeConditions(backConditions) }
        set { backConditions = Self.encodeConditions(newValue) }
    }

    /// True if any condition is recorded on either nine.
    var hasConditions: Bool {
        !frontConditionsValue.isEmpty || !backConditionsValue.isEmpty
    }

    private static func decodeConditions(_ s: String) -> NineConditions {
        guard let data = s.data(using: .utf8), !data.isEmpty,
              let v = try? JSONDecoder().decode(NineConditions.self, from: data)
        else { return NineConditions() }
        return v
    }
    private static func encodeConditions(_ v: NineConditions) -> String {
        (try? JSONEncoder().encode(v)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }

    /// Optional link to a saved Course. Round values above remain as a snapshot
    /// (rating/slope/tees) so old rounds aren't retroactively changed by course edits.
    var course: Course?

    @Relationship(deleteRule: .cascade, inverse: \Hole.round)
    var holes: [Hole] = []

    init(date: Date = .now,
         courseName: String = "",
         tees: String = "",
         courseRating: Double = 72.0,
         slopeRating: Int = 113,
         notes: String = "",
         course: Course? = nil) {
        self.date = date
        self.courseName = courseName
        self.tees = tees
        self.courseRating = courseRating
        self.slopeRating = slopeRating
        self.notes = notes
        self.course = course
        self.idempotencyKey = UUID().uuidString
    }

    var sortedHoles: [Hole] {
        holes.sorted { $0.number < $1.number }
    }

    var isComplete: Bool {
        !holes.isEmpty && holes.allSatisfy { $0.score > 0 }
    }

    /// True when every hole is a par 3 — a par-3 / executive course round.
    /// These are treated as practice, not competitive golf: Stats and
    /// Handicap exclude them so their lower raw scores and unrated tees
    /// don't distort per-9 averages or the differential pool. (Par-3 play
    /// is normally logged as a Practice session; this is the safety net
    /// for any par-3 round that still gets created.)
    var isParThreeCourse: Bool {
        !holes.isEmpty && holes.allSatisfy { $0.par == 3 }
    }

    var totalScore: Int {
        holes.reduce(0) { $0 + $1.score }
    }

    var totalPar: Int {
        holes.reduce(0) { $0 + $1.par }
    }

    var scoreToPar: Int {
        totalScore - totalPar
    }

    /// Number of holes actually carried by this round (9 or 18 in practice).
    /// Used for normalizing averages so 9- and 18-hole rounds are comparable.
    var holeCount: Int { holes.count }

    /// Score normalized to a per-9-holes basis — handles 9- and 18-hole
    /// rounds fairly. A 44 on 9 and an 84 on 18 both read as ~44/9.
    var scorePer9: Double {
        guard holeCount > 0 else { return 0 }
        return Double(totalScore) / Double(holeCount) * 9
    }

    /// Score-to-par normalized per 9 holes. A +8 on 9 and +16 on 18 match.
    var scoreToParPer9: Double {
        guard holeCount > 0 else { return 0 }
        return Double(scoreToPar) / Double(holeCount) * 9
    }

    var par4Or5Holes: [Hole] {
        holes.filter { $0.par >= 4 }
    }

    var fairwaysHit: Int {
        par4Or5Holes.filter { $0.fairwayHit }.count
    }

    var fairwayAttempts: Int {
        par4Or5Holes.count
    }

    var fairwayPercentage: Double {
        guard fairwayAttempts > 0 else { return 0 }
        return Double(fairwaysHit) / Double(fairwayAttempts) * 100
    }

    var greensInRegulation: Int {
        holes.filter { $0.greenInRegulation }.count
    }

    var girPercentage: Double {
        guard !holes.isEmpty else { return 0 }
        return Double(greensInRegulation) / Double(holes.count) * 100
    }

    var totalPutts: Int {
        holes.reduce(0) { $0 + $1.putts }
    }

    var averagePutts: Double {
        guard !holes.isEmpty else { return 0 }
        return Double(totalPutts) / Double(holes.count)
    }

    /// USGA-style score differential for THIS round's length.
    /// - 18-hole rounds: `(113 / slope) × (adjusted - courseRating)`
    /// - 9-hole rounds:  `(113 / slope) × (adjusted - courseRating / 2)`
    ///
    /// Uses adjusted gross score (net double bogey cap per hole). A 9-hole
    /// differential is not directly usable as an 18-hole handicap input —
    /// two 9-hole differentials are paired chronologically in
    /// `HandicapView` to produce one 18-hole-equivalent differential, per
    /// the World Handicap System (Rule 5.1 / Appendix E).
    var scoreDifferential: Double {
        guard slopeRating > 0, isComplete else { return 0 }
        let adjusted = holes.reduce(0) { sum, hole in
            let netDoubleBogey = hole.par + 2
            return sum + min(hole.score, netDoubleBogey)
        }
        // courseRating on the round is snapshotted from the 18-hole tee
        // rating. For a 9-hole round we halve it — the USGA 9-hole rating
        // on the same tees.
        let rating = holeCount == 9 ? courseRating / 2.0 : courseRating
        return (113.0 / Double(slopeRating)) * (Double(adjusted) - rating)
    }
}

// MARK: - Round-pool eligibility
//
// The app's data-honesty policy lives here, next to the flags it reads, so
// every consumer (Stats, Handicap, future views) shares one definition.
// A view that hand-rolls its own filter is the bug this prevents.
extension Round {
    /// Totals are trustworthy. Reconstructed rounds qualify (their totals
    /// sum correctly even if hole detail was synthesized); par-3 course
    /// rounds and archived rounds do not (par-3 play is practice).
    var isScoringEligible: Bool {
        totalScore > 0 && !isArchived && !isParThreeCourse
    }

    /// Strict pool — per-hole fields (fairways / GIR / putts) are real, not
    /// synthesized. Used for the rate-based stats. Excludes reconstructed.
    var isStatsEligible: Bool {
        isScoringEligible && !isReconstructed
    }

    /// Eligible for the WHS differential pool: a complete card on a rated
    /// tee (slope > 0 — unrated/par-3 tees can't produce a valid
    /// differential, and a slope of 0 would otherwise yield a fake 0.0),
    /// not archived, not a par-3 course.
    var isHandicapEligible: Bool {
        isComplete && !isArchived && !isParThreeCourse && slopeRating > 0
    }
}

// MARK: - Score formatting

extension Int {
    /// Score relative to par, rendered consistently everywhere:
    /// "-2" / "E" / "+3". Replaces the ad-hoc `sign + value` strings that
    /// disagreed on even par ("E" in some views, "+0" in others).
    var toParText: String {
        self == 0 ? "E" : (self > 0 ? "+\(self)" : "\(self)")
    }
}
