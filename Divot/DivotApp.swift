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
            PrepPlan.self,
            VideoBookmark.self,
            TrainingExercise.self,
            TrainingSession.self,
            PerformedExercise.self,
            AuditEntry.self
        ])
        let container = Self.makeContainer(schema: schema)

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
        // Auto-backup on quit — pushes the session you just finished (only
        // when something actually changed). The manual Backup button remains.
        BackupTrigger.installAutoBackupOnQuit(container: container)
        self.container = container
    }

    /// Build the on-disk store, recovering gracefully instead of crashing.
    /// A `fatalError` here used to mean a corrupt or un-migratable store
    /// locked the user out of the app entirely — with no way to even
    /// rescue the old data. Recovery ladder:
    ///   1. Open the store normally.
    ///   2. On failure, move the store aside (preserved as
    ///      `default.store.corrupt-<stamp>` for manual recovery) and retry
    ///      with a fresh store, telling the user.
    ///   3. Last resort, run in-memory so the app still launches.
    /// Only an invalid *schema* (a build-time programmer error, not user
    /// data) can reach the final trap.
    private static func makeContainer(schema: Schema) -> ModelContainer {
        let onDisk = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let c = try? ModelContainer(for: schema, configurations: [onDisk]) {
            return c
        }
        NSLog("Divot: store failed to open; moving it aside and retrying fresh.")
        moveStoreAside()
        if let c = try? ModelContainer(for: schema, configurations: [onDisk]) {
            Task { @MainActor in
                ErrorReporter.shared.report(
                    "Your saved data couldn't be opened and was moved aside "
                    + "(default.store.corrupt-… in the app's Application Support "
                    + "folder). Divot started with a fresh store.")
            }
            return c
        }
        NSLog("Divot: fresh store also failed; falling back to in-memory.")
        let inMemory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        if let c = try? ModelContainer(for: schema, configurations: [inMemory]) {
            Task { @MainActor in
                ErrorReporter.shared.report(
                    "Running in temporary memory — changes won't be saved. "
                    + "Your store was moved aside for recovery.")
            }
            return c
        }
        fatalError("Could not create any ModelContainer — the schema itself is invalid.")
    }

    /// Rename the live store files so a fresh one can be created, keeping the
    /// originals for manual recovery.
    private static func moveStoreAside() {
        let fm = FileManager.default
        guard let dir = try? fm.url(for: .applicationSupportDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil, create: false) else { return }
        let stamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        for suffix in ["", "-wal", "-shm"] {
            let src = dir.appendingPathComponent("default.store\(suffix)")
            guard fm.fileExists(atPath: src.path) else { continue }
            let dst = dir.appendingPathComponent("default.store.corrupt-\(stamp)\(suffix)")
            try? fm.moveItem(at: src, to: dst)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .overlay(alignment: .top) { ErrorBanner() }
        }
        .modelContainer(container)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            SidebarCommands()
        }
    }
}
