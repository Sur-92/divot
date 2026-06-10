import XCTest
@testable import Divot

final class AuditHashTests: XCTestCase {
    func testCanonicalContentStable() {
        let t = Date(timeIntervalSince1970: 1_700_000_000)
        let a = AuditEntry.canonicalContent(sequence: 5, timestamp: t,
                                            entityType: "Round", entityID: "abc",
                                            action: "insert", summary: "Started")
        let b = AuditEntry.canonicalContent(sequence: 5, timestamp: t,
                                            entityType: "Round", entityID: "abc",
                                            action: "insert", summary: "Started")
        XCTAssertEqual(a, b)
        XCTAssertTrue(a.contains("Round"))
        XCTAssertTrue(a.contains("insert"))
    }

    func testSha256KnownValue() {
        // SHA-256("abc") is a published constant — pins the hashing.
        XCTAssertEqual(
            AuditEntry.sha256Hex("abc"),
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    func testChainHashChangesWithContent() {
        let h1 = AuditEntry.sha256Hex("GENESIS" + "content-A")
        let h2 = AuditEntry.sha256Hex("GENESIS" + "content-B")
        XCTAssertNotEqual(h1, h2)   // a content edit breaks the chain
    }
}
