import Foundation
import SwiftData

/// Seeds the user's personal bag with the clubs they've told us about.
/// Runs once on first launch; if the user already has clubs, we do nothing.
enum BagSeeder {
    static func seedIfEmpty(context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<BagClub>())) ?? 0
        guard count == 0 else { return }

        let clubs: [BagClub] = [
            BagClub(
                manufacturer: "Ping",
                modelName: "G440",
                year: 2025,
                category: .driver,
                loft: "",
                shaft: "Eventus 6 S",
                notes: "Current gamer driver"
            ),
            BagClub(
                manufacturer: "Cobra",
                modelName: "LD Speed F",
                year: 2007,
                category: .driver,
                loft: "",
                shaft: "",
                notes: "Legacy driver"
            ),
            BagClub(
                manufacturer: "Cobra",
                modelName: "LD Speed King",
                year: 2007,
                category: .fairway,
                loft: "15°",
                shaft: "",
                notes: "3-wood"
            ),
            BagClub(
                manufacturer: "Mizuno",
                modelName: "Irons",
                year: 2024,
                category: .ironSet,
                loft: "",
                shaft: "",
                notes: "2023–2026 vintage (refine model when confirmed)"
            ),
            BagClub(
                manufacturer: "Mizuno",
                modelName: "Putter",
                year: 0,
                category: .putter,
                loft: "",
                shaft: "",
                notes: ""
            )
        ]

        for c in clubs {
            context.insert(c)
        }

        do {
            try context.save()
        } catch {
            print("BagSeeder save failed: \(error)")
        }
    }
}
