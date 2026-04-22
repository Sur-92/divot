import Foundation
import SwiftData

@Model
final class Shot {
    var number: Int
    var club: Club
    var distance: Int         // yards
    var lie: Lie              // lie BEFORE this shot
    var result: ShotResult
    var notes: String = ""
    var idempotencyKey: String = ""
    var hole: Hole?

    init(number: Int,
         club: Club = .iron7,
         distance: Int = 0,
         lie: Lie = .fairway,
         result: ShotResult = .onTarget,
         notes: String = "") {
        self.number = number
        self.club = club
        self.distance = distance
        self.lie = lie
        self.result = result
        self.notes = notes
        self.idempotencyKey = UUID().uuidString
    }
}
