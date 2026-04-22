import Foundation
import SwiftData

/// Backfills `idempotencyKey` on any pre-existing rows that were created
/// before the field was added. New inserts always set the key in `init`;
/// this migration is idempotent and runs on every launch — rows that
/// already have a key are untouched.
enum IdempotencyMigration {
    static func backfill(context: ModelContext) {
        var assigned = 0
        assigned += fill(Round.self, context: context)
        assigned += fill(Hole.self, context: context)
        assigned += fill(Shot.self, context: context)
        assigned += fill(Course.self, context: context)
        assigned += fill(CourseHole.self, context: context)
        assigned += fill(CourseTee.self, context: context)
        assigned += fill(PracticeSession.self, context: context)
        assigned += fill(BagClub.self, context: context)

        if assigned > 0 {
            do {
                try context.save()
            } catch {
                print("IdempotencyMigration save failed: \(error)")
            }
        }
    }

    // MARK: - Per-type backfill

    private static func fill(_ type: Round.Type, context: ModelContext) -> Int {
        let fd = FetchDescriptor<Round>(
            predicate: #Predicate { $0.idempotencyKey == "" }
        )
        let rows = (try? context.fetch(fd)) ?? []
        for r in rows { r.idempotencyKey = UUID().uuidString }
        return rows.count
    }

    private static func fill(_ type: Hole.Type, context: ModelContext) -> Int {
        let fd = FetchDescriptor<Hole>(
            predicate: #Predicate { $0.idempotencyKey == "" }
        )
        let rows = (try? context.fetch(fd)) ?? []
        for r in rows { r.idempotencyKey = UUID().uuidString }
        return rows.count
    }

    private static func fill(_ type: Shot.Type, context: ModelContext) -> Int {
        let fd = FetchDescriptor<Shot>(
            predicate: #Predicate { $0.idempotencyKey == "" }
        )
        let rows = (try? context.fetch(fd)) ?? []
        for r in rows { r.idempotencyKey = UUID().uuidString }
        return rows.count
    }

    private static func fill(_ type: Course.Type, context: ModelContext) -> Int {
        let fd = FetchDescriptor<Course>(
            predicate: #Predicate { $0.idempotencyKey == "" }
        )
        let rows = (try? context.fetch(fd)) ?? []
        for r in rows { r.idempotencyKey = UUID().uuidString }
        return rows.count
    }

    private static func fill(_ type: CourseHole.Type, context: ModelContext) -> Int {
        let fd = FetchDescriptor<CourseHole>(
            predicate: #Predicate { $0.idempotencyKey == "" }
        )
        let rows = (try? context.fetch(fd)) ?? []
        for r in rows { r.idempotencyKey = UUID().uuidString }
        return rows.count
    }

    private static func fill(_ type: CourseTee.Type, context: ModelContext) -> Int {
        let fd = FetchDescriptor<CourseTee>(
            predicate: #Predicate { $0.idempotencyKey == "" }
        )
        let rows = (try? context.fetch(fd)) ?? []
        for r in rows { r.idempotencyKey = UUID().uuidString }
        return rows.count
    }

    private static func fill(_ type: PracticeSession.Type, context: ModelContext) -> Int {
        let fd = FetchDescriptor<PracticeSession>(
            predicate: #Predicate { $0.idempotencyKey == "" }
        )
        let rows = (try? context.fetch(fd)) ?? []
        for r in rows { r.idempotencyKey = UUID().uuidString }
        return rows.count
    }

    private static func fill(_ type: BagClub.Type, context: ModelContext) -> Int {
        let fd = FetchDescriptor<BagClub>(
            predicate: #Predicate { $0.idempotencyKey == "" }
        )
        let rows = (try? context.fetch(fd)) ?? []
        for r in rows { r.idempotencyKey = UUID().uuidString }
        return rows.count
    }
}
