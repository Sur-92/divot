import Foundation
import SwiftData

/// Drives the out-of-app backup agent. Writing `.backup-trigger` into the
/// container's Documents fires the launchd WatchPaths agent, which snapshots
/// the live DB into the private app-data repo and pushes.
///
/// Used by the manual "Backup Data" button and by the automatic on-quit
/// backup. The on-quit path only fires when data actually changed this
/// session, so opening and closing the app without edits won't churn the repo.
enum BackupTrigger {
    /// Flipped true the first time a real save persists changes this session.
    /// Monotonic (only ever set true); a benign data race at worst.
    nonisolated(unsafe) static var dataChangedThisSession = false

    /// Touch the trigger file so launchd runs the backup agent.
    static func fire() {
        guard let docs = try? FileManager.default.url(
            for: .documentDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true) else { return }
        let trigger = docs.appendingPathComponent(".backup-trigger")
        // Non-atomic in-place write so launchd's WatchPaths reliably fires.
        try? "\(Date().timeIntervalSince1970)".data(using: .utf8)?.write(to: trigger)
    }

    /// Back up automatically when the app quits — but only if something was
    /// actually saved this session. Mirrors TempCleaner's termination hook;
    /// runs on the main queue so accessing the main context is safe.
    static func installAutoBackupOnQuit(container: ModelContainer) {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NSApplicationWillTerminateNotification"),
            object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                let ctx = container.mainContext
                if ctx.hasChanges { ctx.saveOrReport("auto-backup on quit") }
                guard dataChangedThisSession else { return }
                fire()
                NSLog("[Divot] auto-backup triggered on quit")
            }
        }
    }
}
