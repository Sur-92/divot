import Foundation
import SwiftData

/// One-time JSON data import that mirrors the seeder pattern but keeps the
/// payload OUT of the (public) repo.
///
/// On launch, if a `divot-import.json` file is present in the app
/// container's Documents directory, its rows are inserted through SwiftData
/// and the file is renamed so it won't run again. Re-importing is safe:
/// rows are de-duplicated by a natural key per entity, so dropping in an
/// updated file only adds what's new.
///
/// The payload is intentionally extensible — add `courses`, `rounds`, etc.
/// sections to `Payload` as more data is filled in.
enum DataImporter {

    // MARK: - Codable payload

    struct Payload: Codable {
        var clubs: [ClubRow]?
    }

    struct ClubRow: Codable {
        var manufacturer: String
        var modelName: String
        var category: String        // ClubCategory rawValue: driver/fairway/hybrid/ironSet/wedge/putter
        var clubNumber: String?
        var loft: String?
        var shaft: String?
        var grip: String?
        var notes: String?
        var year: Int?
        var bagOrder: Int?
        var isRetired: Bool?
    }

    // MARK: - Entry point

    @discardableResult
    static func importIfPresent(context: ModelContext) -> String? {
        let fm = FileManager.default
        guard let docs = try? fm.url(for: .documentDirectory,
                                     in: .userDomainMask,
                                     appropriateFor: nil,
                                     create: false) else { return nil }
        let url = docs.appendingPathComponent("divot-import.json")
        guard fm.fileExists(atPath: url.path) else { return nil }

        guard let data = try? Data(contentsOf: url),
              let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
            print("Divot import: could not read or parse divot-import.json")
            return nil
        }

        var inserted = 0
        if let clubs = payload.clubs {
            inserted += importClubs(clubs, context: context)
        }
        try? context.save()

        // Rename so the import doesn't re-run on the next launch.
        let stamp = ISO8601DateFormatter().string(from: .now)
            .replacingOccurrences(of: ":", with: "-")
        let done = docs.appendingPathComponent("divot-import.imported-\(stamp).json")
        try? fm.moveItem(at: url, to: done)

        let summary = "Divot import: added \(inserted) club(s)"
        print(summary)
        return summary
    }

    // MARK: - Clubs

    private static func importClubs(_ rows: [ClubRow], context: ModelContext) -> Int {
        // De-dup against what's already in the bag (natural key).
        let existing = (try? context.fetch(FetchDescriptor<BagClub>())) ?? []
        var seen = Set(existing.map { key($0.manufacturer, $0.modelName, $0.clubNumber) })

        var count = 0
        for row in rows {
            let category = ClubCategory(rawValue: row.category) ?? .ironSet
            let number = row.clubNumber ?? ""
            let k = key(row.manufacturer, row.modelName, number)
            if seen.contains(k) { continue }
            seen.insert(k)

            let club = BagClub(
                manufacturer: row.manufacturer,
                modelName: row.modelName,
                year: row.year ?? 0,
                category: category,
                loft: row.loft ?? "",
                shaft: row.shaft ?? "",
                notes: row.notes ?? "",
                addedAt: .now,
                bagOrder: row.bagOrder ?? 0,
                clubNumber: number,
                grip: row.grip ?? ""
            )
            club.isRetired = row.isRetired ?? false
            context.insert(club)
            count += 1
        }
        return count
    }

    private static func key(_ manufacturer: String, _ model: String, _ number: String) -> String {
        "\(manufacturer.lowercased())|\(model.lowercased())|\(number.lowercased())"
    }
}
