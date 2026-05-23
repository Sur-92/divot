import Foundation
import SwiftData

@Model
final class Hole {
    var number: Int
    var par: Int
    var score: Int
    var fairwayHit: Bool
    var greenInRegulation: Bool
    var putts: Int
    var notes: String = ""

    /// Stable identity for this row — generated on insert, never changes.
    var idempotencyKey: String = ""

    /// Snapshot of the yardage played on this hole (from the selected tee
    /// at round-creation time). 0 = not captured yet.
    var yardage: Int = 0

    /// Snapshot of the course's hole handicap index (1=hardest, 18=easiest).
    /// 0 = not captured yet.
    var handicapIndex: Int = 0

    /// Penalty strokes taken on this hole. 0 = none.
    var penalties: Int = 0

    /// Number of bunker (sand) shots on this hole. 0 = none.
    var bunkerShots: Int = 0

    /// Tee-shot landing plot. `hasDrive` gates X/Y so a fresh hole (0.5,0.5)
    /// isn't read as a real center plot. X: 0 = far left … 1 = far right.
    /// Y: 0 = short … 1 = long. Band edges below classify X into
    /// rough / fringe / fairway.
    var hasDrive: Bool = false
    var driveX: Double = 0.5
    var driveY: Double = 0.5

    var round: Round?

    @Relationship(deleteRule: .cascade, inverse: \Shot.hole)
    var shots: [Shot] = []

    init(number: Int,
         par: Int = 4,
         score: Int = 0,
         fairwayHit: Bool = false,
         greenInRegulation: Bool = false,
         putts: Int = 0,
         notes: String = "",
         yardage: Int = 0,
         handicapIndex: Int = 0) {
        self.number = number
        self.par = par
        self.score = score
        self.fairwayHit = fairwayHit
        self.greenInRegulation = greenInRegulation
        self.putts = putts
        self.notes = notes
        self.yardage = yardage
        self.handicapIndex = handicapIndex
        self.idempotencyKey = UUID().uuidString
    }

    var scoreToPar: Int { score > 0 ? score - par : 0 }

    var sortedShots: [Shot] {
        shots.sorted { $0.number < $1.number }
    }

    // MARK: - Drive landing zones
    // Lateral band edges, as a fraction of corridor width (0 = far left … 1 = far right).
    static let bandLFringe = 0.18
    static let bandFairwayStart = 0.30
    static let bandFairwayEnd = 0.70
    static let bandRRough = 0.82

    var driveInFairway: Bool { hasDrive && driveX >= Hole.bandFairwayStart && driveX < Hole.bandFairwayEnd }
    var driveMissLeft: Bool  { hasDrive && driveX < Hole.bandFairwayStart }
    var driveMissRight: Bool { hasDrive && driveX >= Hole.bandFairwayEnd }
    var driveInRough: Bool   { hasDrive && (driveX < Hole.bandLFringe || driveX >= Hole.bandRRough) }
    var driveShort: Bool     { hasDrive && driveY < 0.40 }
    var driveLong: Bool      { hasDrive && driveY > 0.70 }

    /// Compact label for the scorecard glyph.
    var driveZoneLabel: String {
        guard hasDrive else { return "" }
        if driveX < Hole.bandLFringe { return "Rgh L" }
        if driveX < Hole.bandFairwayStart { return "Frg L" }
        if driveX < Hole.bandFairwayEnd { return "FW" }
        if driveX < Hole.bandRRough { return "Frg R" }
        return "Rgh R"
    }
}
