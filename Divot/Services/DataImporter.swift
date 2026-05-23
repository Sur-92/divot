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
        /// Entity sections to wipe before importing — e.g. ["clubs"],
        /// ["courses"]. Lets a corrected file fully replace a section instead
        /// of merging into it.
        var reset: [String]?
        var clubs: [ClubRow]?
        var courses: [CourseRow]?
    }

    struct CourseRow: Codable {
        var name: String
        var address: String?
        var phone: String?
        var designer: String?
        var openedYear: Int?
        var totalPar: Int?
        var bookingURL: String?
        var latitude: Double?
        var longitude: Double?
        var isSimulator: Bool?
        var holes: [HoleRow]?
        var tees: [TeeRow]?
    }

    struct HoleRow: Codable {
        var number: Int
        var par: Int?
        var handicapIndex: Int?
    }

    struct TeeRow: Codable {
        var name: String
        var yardage: Int?
        var courseRating: Double?
        var slopeRating: Int?
        var yardages: [Int]?
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

        // Wipe requested sections first so a corrected file fully replaces them.
        let reset = Set(payload.reset ?? [])
        var deletedClubs = 0
        if reset.contains("clubs") {
            let all = (try? context.fetch(FetchDescriptor<BagClub>())) ?? []
            for club in all { context.delete(club) }
            deletedClubs = all.count
            try? context.save()
        }
        var deletedCourses = 0
        if reset.contains("courses") {
            let all = (try? context.fetch(FetchDescriptor<Course>())) ?? []
            for course in all { context.delete(course) }   // cascades to holes/tees
            deletedCourses = all.count
            try? context.save()
        }

        var insertedClubs = 0
        if let clubs = payload.clubs {
            insertedClubs += importClubs(clubs, context: context)
        }
        var insertedCourses = 0
        if let courses = payload.courses {
            insertedCourses += importCourses(courses, context: context)
        }
        try? context.save()

        // Rename so the import doesn't re-run on the next launch.
        let stamp = ISO8601DateFormatter().string(from: .now)
            .replacingOccurrences(of: ":", with: "-")
        let done = docs.appendingPathComponent("divot-import.imported-\(stamp).json")
        try? fm.moveItem(at: url, to: done)

        let summary = "Divot import: clubs −\(deletedClubs)/+\(insertedClubs), courses −\(deletedCourses)/+\(insertedCourses)"
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

    // MARK: - Courses

    private static func importCourses(_ rows: [CourseRow], context: ModelContext) -> Int {
        // De-dup by course name.
        let existing = (try? context.fetch(FetchDescriptor<Course>())) ?? []
        var seen = Set(existing.map { $0.name.lowercased() })

        var count = 0
        for row in rows {
            if seen.contains(row.name.lowercased()) { continue }
            seen.insert(row.name.lowercased())

            let course = Course(
                name: row.name,
                address: row.address ?? "",
                phone: row.phone ?? "",
                designer: row.designer ?? "",
                openedYear: row.openedYear ?? 0,
                totalPar: row.totalPar ?? 72
            )
            course.bookingURL = row.bookingURL ?? ""
            course.latitude = row.latitude ?? 0
            course.longitude = row.longitude ?? 0
            course.isSimulator = row.isSimulator ?? false
            context.insert(course)

            if let holes = row.holes {
                for h in holes {
                    let hole = CourseHole(number: h.number,
                                          par: h.par ?? 4,
                                          handicapIndex: h.handicapIndex ?? 0)
                    hole.course = course
                    context.insert(hole)
                }
                let summed = holes.reduce(0) { $0 + ($1.par ?? 4) }
                if summed > 0 { course.totalPar = summed }
            }

            if let tees = row.tees {
                for t in tees {
                    let tee = CourseTee(name: t.name,
                                        yardage: t.yardage ?? (t.yardages?.reduce(0, +) ?? 0),
                                        courseRating: t.courseRating ?? 0,
                                        slopeRating: t.slopeRating ?? 0,
                                        yardages: t.yardages ?? [])
                    tee.course = course
                    context.insert(tee)
                }
            }

            count += 1
        }
        return count
    }
}
