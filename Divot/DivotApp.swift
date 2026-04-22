import SwiftUI
import SwiftData

@main
struct DivotApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            Round.self,
            Hole.self,
            Shot.self,
            Course.self,
            CourseTee.self,
            CourseHole.self,
            BagClub.self,
            PracticeSession.self,
            AuditEntry.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            CourseSeeder.seedIfEmpty(context: container.mainContext)
            CourseSeeder.migrateRoyalOaksIfNeeded(context: container.mainContext)
            CourseSeeder.seedIronValleyIfNeeded(context: container.mainContext)
            CourseSeeder.migrateIronValleyHandicapsIfNeeded(context: container.mainContext)
            CourseSeeder.seedFairviewIfNeeded(context: container.mainContext)
            CourseSeeder.migrateFairviewHandicapsIfNeeded(context: container.mainContext)
            CourseSeeder.seedPineMeadowsIfNeeded(context: container.mainContext)
            CourseSeeder.seedDauphinHighlandsIfNeeded(context: container.mainContext)
            CourseSeeder.seedBlueMountainIfNeeded(context: container.mainContext)
            CourseSeeder.seedFoxchaseIfNeeded(context: container.mainContext)
            CourseSeeder.seedDeerValleyIfNeeded(context: container.mainContext)
            BagSeeder.seedIfEmpty(context: container.mainContext)
            // After all seeders run, stamp any rows missing an idempotency key.
            IdempotencyMigration.backfill(context: container.mainContext)
            // Connect the audit log to the ModelContainer. AuditService uses
            // its own per-call ModelContext so it never interferes with the
            // view's context during active writes.
            Task { @MainActor in
                AuditService.shared.configure(container: container)
            }
            self.container = container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            SidebarCommands()
        }
    }
}
