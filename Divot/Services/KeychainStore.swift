import Foundation
import Security

/// Minimal Keychain wrapper for the user's Anthropic API key. The key is a
/// secret, so it never touches UserDefaults or the repo — this is the only
/// place it's persisted, in the login keychain, scoped to this app.
enum KeychainStore {
    static let service = "com.roadandrock.Divot"
    static let anthropicKeyAccount = "anthropic-api-key"

    @discardableResult
    static func set(_ value: String, account: String) -> Bool {
        delete(account: account)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: Data(value.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    static func get(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }

    @discardableResult
    static func delete(account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // Convenience for the one secret stored today.
    static var anthropicKey: String? { get(account: anthropicKeyAccount) }
    static var hasAnthropicKey: Bool { anthropicKey?.isEmpty == false }
    @discardableResult
    static func setAnthropicKey(_ v: String) -> Bool { set(v, account: anthropicKeyAccount) }
    @discardableResult
    static func clearAnthropicKey() -> Bool { delete(account: anthropicKeyAccount) }
}
