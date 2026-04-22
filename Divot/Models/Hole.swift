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
}
