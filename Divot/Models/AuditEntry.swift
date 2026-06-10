import Foundation
import SwiftData
import CryptoKit

/// Append-only, hash-chained change log.
///
/// Every meaningful write to the app's data (round created, shot deleted,
/// course edited, etc.) appends one row. Each row carries `previousHash`
/// (the prior entry's hash) and `entryHash` (SHA-256 of `previousHash +
/// <canonical content>`). `AuditService.verify()` walks the chain and
/// flags any break in continuity.
///
/// Scope of the guarantee: this detects *accidental* corruption and
/// out-of-band edits that don't recompute the chain. It is NOT
/// cryptographically tamper-proof — the hash is unkeyed, so anyone who
/// can rewrite the store could also recompute every downstream hash, and
/// truncating the newest rows leaves a shorter-but-valid chain. For a
/// single-user local app that's the right trade; don't market it as
/// tamper-proof. (A keyed HMAC + an external high-water mark would close
/// both gaps if this ever needs to be adversarial.)
@Model
final class AuditEntry {
    /// Monotonic sequence counter — entry #1, #2, #3…
    var sequence: Int

    /// When the logged event happened.
    var timestamp: Date

    /// Entity class — "Round", "Shot", "Course", "BagClub", etc.
    var entityType: String

    /// The subject's idempotency key (UUID string), if applicable.
    var entityID: String

    /// Human-readable label like "Course Round · Apr 18".
    var entityLabel: String

    /// "insert", "update", "delete", "archive", "restore", "reorder", etc.
    var action: String

    /// Human-readable summary like "Round created at the course".
    var summary: String

    /// Hex SHA-256 of the previous entry's `entryHash`, or "GENESIS" for row #1.
    var previousHash: String

    /// Hex SHA-256 of `previousHash + canonicalContent`.
    ///
    /// IMPORTANT — named `entryHash` NOT `hash`. NSManagedObject (which @Model
    /// classes inherit from) already has a stored `hash: Int` property. A
    /// stored `var hash: String` on an @Model collides at KVC-level: SwiftData's
    /// read path resolves the Int from NSObject and dynamic-casts to String,
    /// which aborts the process with swift_dynamicCastFailure. Do not rename
    /// back.
    var entryHash: String

    init(sequence: Int,
         timestamp: Date,
         entityType: String,
         entityID: String,
         entityLabel: String,
         action: String,
         summary: String,
         previousHash: String,
         entryHash: String) {
        self.sequence = sequence
        self.timestamp = timestamp
        self.entityType = entityType
        self.entityID = entityID
        self.entityLabel = entityLabel
        self.action = action
        self.summary = summary
        self.previousHash = previousHash
        self.entryHash = entryHash
    }

    /// Canonical content hashed into the chain — stable string derived
    /// from fields that shouldn't change after the row is written.
    static func canonicalContent(sequence: Int,
                                 timestamp: Date,
                                 entityType: String,
                                 entityID: String,
                                 action: String,
                                 summary: String) -> String {
        "\(sequence)|\(Int(timestamp.timeIntervalSince1970 * 1000))|\(entityType)|\(entityID)|\(action)|\(summary)"
    }

    static func sha256Hex(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
