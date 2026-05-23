import SwiftUI
import SwiftData

@main
struct DivotApp: App {
    let container: ModelContainer

    init() {
        // Wipe transient caches (tmp/, Caches/, HTTPStorages/) at launch
        // and register the same wipe at termination. Keeps the app
        // container free of stale CFNetworkDownload tmp files and any
        // URL-cache crumbs from PGAService fetches.
        TempCleaner.runAtLaunch()
        TempCleaner.installTerminationHandler()

        let schema = Schema([
            Round.self,
            Hole.self,
            Shot.self,
            Course.self,
            CourseTee.self,
            CourseHole.self,
            BagClub.self,
            PracticeSession.self,
            VideoBookmark.self,
            TrainingExercise.self,
            TrainingSession.self,
            PerformedExercise.self,
            AuditEntry.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            // The public build ships empty — courses, clubs, rounds, etc.
            // are all added by the user through the UI. CourseSeeder /
            // BagSeeder are kept as extension points: drop your own
            // private seeders into them if you want first-launch defaults.
            CourseSeeder.seedIfEmpty(context: container.mainContext)
            BagSeeder.seedIfEmpty(context: container.mainContext)
            // Import a drop-in divot-import.json from the app container's
            // Documents dir, if present. Keeps private data out of the repo.
            DataImporter.importIfPresent(context: container.mainContext)
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
