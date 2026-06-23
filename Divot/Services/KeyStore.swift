import Foundation

/// Stores the user's Anthropic API key as a plain file in the app's own
/// container (Application Support) — NOT in the Keychain, NOT compiled into
/// the binary, NOT in git. The key never ships in a build; it lives only on
/// this machine. A `.gitignore` entry covers any copy left in the working
/// tree, and the file is written 0600 (owner read/write only).
enum KeyStore {
    private static let fileName = "anthropic-key.txt"

    private static var fileURL: URL? {
        let fm = FileManager.default
        guard let dir = try? fm.url(for: .applicationSupportDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil, create: true)
        else { return nil }
        return dir.appendingPathComponent(fileName)
    }

    static var anthropicKey: String? {
        guard let url = fileURL,
              let raw = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static var hasAnthropicKey: Bool { anthropicKey != nil }

    @discardableResult
    static func setAnthropicKey(_ value: String) -> Bool {
        guard let url = fileURL else { return false }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try trimmed.write(to: url, atomically: true, encoding: .utf8)
            try? FileManager.default.setAttributes(
                [.posixPermissions: 0o600], ofItemAtPath: url.path)
            return true
        } catch {
            return false
        }
    }

    @discardableResult
    static func clearAnthropicKey() -> Bool {
        guard let url = fileURL else { return false }
        try? FileManager.default.removeItem(at: url)
        return true
    }
}
