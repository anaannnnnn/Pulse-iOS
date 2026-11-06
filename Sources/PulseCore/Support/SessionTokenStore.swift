import Foundation
#if canImport(Security)
import Security
#endif

/// Keeps the server's session token so the app stays signed in between launches.
/// Uses the Keychain on Apple platforms and memory elsewhere (Linux tests).
public final class SessionTokenStore: @unchecked Sendable {
    private let account: String
    private let lock = NSLock()
    private var memory: String?

    public init(server: URL) { account = "session@" + (server.host ?? server.absoluteString) }

    public func load() -> String? {
        lock.lock(); defer { lock.unlock() }
        #if canImport(Security)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "online.devxpert.pulse.session",
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var out: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &out) == errSecSuccess, let data = out as? Data else { return nil }
        return String(data: data, encoding: .utf8)
        #else
        return memory
        #endif
    }

    public func save(_ token: String?) {
        lock.lock(); defer { lock.unlock() }
        #if canImport(Security)
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "online.devxpert.pulse.session",
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(base as CFDictionary)
        guard let token, let data = token.data(using: .utf8) else { return }
        var item = base
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(item as CFDictionary, nil)
        #else
        memory = token
        #endif
    }
}
