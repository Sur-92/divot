import Foundation
import SwiftData

/// Central append-only audit logger with hash-chain verification.
///
/// Configure once at app launch with a ModelContainer, then call
/// `log(...)` from any write path that should leave a trail. Entries
/// are chained: each row's `hash` incorporates the previous row's hash
/// plus the current row's canonical content.
///
/// Uses a dedicated per-call ModelContext so it never interacts with
/// the main view context's in-flight state. Callers are expected to
/// have already saved any domain changes on their own context before
/// calling `log(...)`.
@MainActor
final class AuditService {
    static let shared = AuditService()
    private init() {}

    private var container: ModelContainer?

    // MARK: - Configuration

    func configure(container: ModelContainer) {
        self.container = container
    }

    // MARK: - Logging

    func log(entityType: String,
             entityID: String,
             entityLabel: String,
             action: String,
             summary: String,
             at date: Date = .now) {
        guard let container else { return }

        // Dedicated context — isolates audit writes from the UI context's
        // dirty state. Any swift_dynamicCast hiccup in the main context
        // (old rows mid-materialization) won't poison the log.
        let context = ModelContext(container)

        // Fetch the previous (highest-sequence) entry.
        var fd = FetchDescriptor<AuditEntry>(
            sortBy: [SortDescriptor(\.sequence, order: .reverse)]
        )
        fd.fetchLimit = 1
        let previous = (try? context.fetch(fd))?.first

        let previousHash = previous?.entryHash ?? "GENESIS"
        let sequence = (previous?.sequence ?? 0) + 1

        let content = AuditEntry.canonicalContent(
            sequence: sequence,
            timestamp: date,
            entityType: entityType,
            entityID: entityID,
            action: action,
            summary: summary
        )
        let entryHash = AuditEntry.sha256Hex(previousHash + content)

        let entry = AuditEntry(
            sequence: sequence,
            timestamp: date,
            entityType: entityType,
            entityID: entityID,
            entityLabel: entityLabel,
            action: action,
            summary: summary,
            previousHash: previousHash,
            entryHash: entryHash
        )
        context.insert(entry)
        try? context.save()
    }

    // MARK: - Reads
    //
    // We intentionally fetch via a dedicated ModelContext instead of
    // exposing AuditEntry to SwiftUI's @Query on the main context. The
    // main context has been observed to fail a `swift_dynamicCast` when
    // binding AuditEntry rows — likely a SwiftData migration/cache quirk
    // with a late-added @Model. A fresh context reads cleanly.

    /// Fetches all audit entries, newest first by sequence.
    func fetchAllDescending() -> [AuditEntry] {
        guard let container else { return [] }
        let context = ModelContext(container)
        let fd = FetchDescriptor<AuditEntry>(
            sortBy: [SortDescriptor(\.sequence, order: .reverse)]
        )
        return (try? context.fetch(fd)) ?? []
    }

    // MARK: - Verification

    struct VerifyResult {
        let isValid: Bool
        let entryCount: Int
        let firstBreakAt: Int?   // sequence number of first broken entry
        let brokenHash: String?
    }

    func verify() -> VerifyResult {
        guard let container else {
            return VerifyResult(isValid: false, entryCount: 0, firstBreakAt: nil, brokenHash: nil)
        }
        let context = ModelContext(container)
        let fd = FetchDescriptor<AuditEntry>(
            sortBy: [SortDescriptor(\.sequence, order: .forward)]
        )
        let entries = (try? context.fetch(fd)) ?? []
        var prevHash = "GENESIS"
        for (i, entry) in entries.enumerated() {
            // Verify previousHash matches
            if entry.previousHash != prevHash {
                return VerifyResult(isValid: false,
                                    entryCount: entries.count,
                                    firstBreakAt: entry.sequence,
                                    brokenHash: entry.entryHash)
            }
            // Verify sequence is continuous
            if entry.sequence != i + 1 {
                return VerifyResult(isValid: false,
                                    entryCount: entries.count,
                                    firstBreakAt: entry.sequence,
                                    brokenHash: entry.entryHash)
            }
            // Verify content hash
            let content = AuditEntry.canonicalContent(
                sequence: entry.sequence,
                timestamp: entry.timestamp,
                entityType: entry.entityType,
                entityID: entry.entityID,
                action: entry.action,
                summary: entry.summary
            )
            let expected = AuditEntry.sha256Hex(prevHash + content)
            if expected != entry.entryHash {
                return VerifyResult(isValid: false,
                                    entryCount: entries.count,
                                    firstBreakAt: entry.sequence,
                                    brokenHash: entry.entryHash)
            }
            prevHash = entry.entryHash
        }
        return VerifyResult(isValid: true,
                            entryCount: entries.count,
                            firstBreakAt: nil,
                            brokenHash: nil)
    }
}
