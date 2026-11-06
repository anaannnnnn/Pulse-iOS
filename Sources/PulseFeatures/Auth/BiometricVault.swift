#if canImport(SwiftUI) && canImport(UIKit)
import Foundation
import LocalAuthentication
import Security

/// Keeps the account email and password in the Keychain behind Face ID / Touch ID so sign-in is one look.
enum BiometricVault {
    struct Credentials: Codable { let email: String; let password: String }

    private static let service = "app.pulse.credentials"
    private static let account = "login"

    static var availableType: LABiometryType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else { return .none }
        return context.biometryType
    }

    static var symbol: String { availableType == .touchID ? "touchid" : "faceid" }
    static var name: String { availableType == .touchID ? "Touch ID" : "Face ID" }
    static var isAvailable: Bool { availableType != .none }

    static var hasStoredCredentials: Bool {
        let context = LAContext()
        context.interactionNotAllowed = true
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account,
            kSecUseAuthenticationContext as String: context, kSecReturnData as String: false,
        ]
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess || status == errSecInteractionNotAllowed
    }

    @discardableResult
    static func store(email: String, password: String) -> Bool {
        remove()
        guard let data = try? JSONEncoder().encode(Credentials(email: email, password: password)),
              let access = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, .biometryCurrentSet, nil)
        else { return false }
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account,
            kSecValueData as String: data, kSecAttrAccessControl as String: access,
        ]
        return SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess
    }

    static func remove() {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account]
        SecItemDelete(query as CFDictionary)
    }

    /// Prompts for Face ID and returns the stored login, or nil if cancelled or failed.
    static func read(reason: String) async -> Credentials? {
        await withCheckedContinuation { continuation in
            let context = LAContext()
            context.localizedReason = reason
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account,
                kSecReturnData as String: true, kSecUseAuthenticationContext as String: context,
            ]
            DispatchQueue.global(qos: .userInitiated).async {
                var item: CFTypeRef?
                let status = SecItemCopyMatching(query as CFDictionary, &item)
                if status == errSecSuccess, let data = item as? Data { continuation.resume(returning: try? JSONDecoder().decode(Credentials.self, from: data)) }
                else { continuation.resume(returning: nil) }
            }
        }
    }
}
#endif
