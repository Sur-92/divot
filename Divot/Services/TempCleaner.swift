import Foundation

/// Wipes the app's transient on-disk state — `tmp/`, `Library/Caches/`,
/// and `Library/HTTPStorages/` — plus the in-memory `URLCache`. Runs at
/// launch and at termination so stale `CFNetworkDownload_*.tmp` files
/// and URL/cookie caches don't pile up across sessions.
///
/// SwiftData's store lives in `Library/Application Support/` and is
/// explicitly NOT touched.
enum TempCleaner {

    static func runAtLaunch() {
        wipe(reason: "launch")
    }

    static func installTerminationHandler() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NSApplicationWillTerminateNotification"),
            object: nil,
            queue: .main
        ) { _ in
            wipe(reason: "terminate")
        }
    }

    private static func wipe(reason: String) {
        let fm = FileManager.default

        // 1. tmp/ — drained completely
        let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
        emptyContents(of: tmpDir, fm: fm)

        // 2. Library/Caches/ — drained completely (URL cache lives here too)
        if let caches = fm.urls(for: .cachesDirectory, in: .userDomainMask).first {
            emptyContents(of: caches, fm: fm)
        }

        // 3. Library/HTTPStorages/ — cookies + per-session URL cache from
        //    URLSession (and any downstream NSWorkspace-adjacent fetches).
        if let library = fm.urls(for: .libraryDirectory, in: .userDomainMask).first {
            let httpStorages = library.appendingPathComponent("HTTPStorages",
                                                              isDirectory: true)
            emptyContents(of: httpStorages, fm: fm)
        }

        // 4. In-memory URL cache shared by URLSession.shared
        URLCache.shared.removeAllCachedResponses()

        NSLog("[Divot] TempCleaner ran at \(reason)")
    }

    private static func emptyContents(of dir: URL, fm: FileManager) {
        guard let entries = try? fm.contentsOfDirectory(at: dir,
                                                        includingPropertiesForKeys: nil,
                                                        options: [.skipsHiddenFiles])
        else { return }
        for entry in entries {
            try? fm.removeItem(at: entry)
        }
    }
}
