import Foundation
import SwiftData

@Model
final class CourseTee {
    var name: String
    var yardage: Int               // total — auto-synced to sum(yardages) when edited
    var courseRating: Double
    var slopeRating: Int
    var course: Course?

    var idempotencyKey: String = ""

    /// Per-hole yardages, ordered by hole number (18 entries when fully populated).
    var yardages: [Int] = []

    init(name: String,
         yardage: Int,
         courseRating: Double,
         slopeRating: Int,
         yardages: [Int] = []) {
        self.name = name
        self.yardage = yardage
        self.courseRating = courseRating
        self.slopeRating = slopeRating
        self.yardages = yardages
        self.idempotencyKey = UUID().uuidString
    }

    /// Yardage for a specific hole number (1-based). Returns 0 if unset.
    func yardage(forHole holeNumber: Int) -> Int {
        let idx = holeNumber - 1
        guard idx >= 0, idx < yardages.count else { return 0 }
        return yardages[idx]
    }
}
