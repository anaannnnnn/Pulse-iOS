#if canImport(SwiftUI) && canImport(UIKit)
import Foundation
import LocalAuthentication
import Security

/// Stores the Pulse passcode in the Keychain behind Face ID / Touch ID so the keypad can be skipped.
enum BiometricVault {
    private static let service = "app.pulse.passcode"
    private static let account = "pin"

    static var availableType: LABiometryType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else { return .none }
        return context.biometryType
    }

    static var symbol: String { availableType == .touchID ? "touchid" : "faceid" }
    static var name: String { availableType == .touchID ? "Touch ID" : "Face ID" }
    static var isAvailable: Bool { availableType != .none }

    static var hasStoredPIN: Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account,
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUIFail, kSecReturnData as String: false,
        ]
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess || status == errSecInteractionNotAllowed
    }

    static func store(pin: String) -> Bool {
        remove()
        guard let access = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, .biometryCurrentSet, nil) else { return false }
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account,
            kSecValueData as String: Data(pin.utf8), kSecAttrAccessControl as String: access,
        ]
        return SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess
    }

    static func remove() {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account]
        SecItemDelete(query as CFDictionary)
    }

    /// Prompts for Face ID and returns the stored passcode, or nil if cancelled/failed.
    static func readPIN(reason: String) async -> String? {
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
                if status == errSecSuccess, let data = item as? Data { continuation.resume(returning: String(data: data, encoding: .utf8)) }
                else { continuation.resume(returning: nil) }
            }
        }
    }
}
#endif
