import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()

    // Keychain service identifiers
    private let tokenService = "mealie.api.token"
    private let serverURLService = "mealie.server.url"

    // Legacy UserDefaults key (for migration)
    private let legacyServerURLKey = "mealie.server.url"

    private init() {
        // Migrate server URL from UserDefaults to Keychain if needed
        migrateServerURLToKeychain()
    }

    // MARK: - Migration

    /// Migrates server URL from UserDefaults to Keychain (one-time migration)
    private func migrateServerURLToKeychain() {
        // Check if there's a URL in UserDefaults that needs migration
        if let legacyURLString = UserDefaults.standard.string(forKey: legacyServerURLKey),
           let legacyURL = URL(string: legacyURLString) {
            // Only migrate if Keychain doesn't already have a URL
            if getServerURL() == nil {
                _ = saveServerURL(legacyURL)
                print("🔐 Migrated server URL from UserDefaults to Keychain")
            }
            // Remove from UserDefaults after migration
            UserDefaults.standard.removeObject(forKey: legacyServerURLKey)
        }
    }

    // MARK: - Token Storage

    /// Saves the token into the Keychain. Returns True if it's successful
    /// - Parameters:
    ///     - token: Token to Authenticate this with.
    ///     - serverURL: The Server URL to hit
    /// - Returns: True if save is successful. False otherwise.
    func saveToken(_ token: String, serverURL: URL) -> Bool {
        guard let data = token.data(using: .utf8) else { return false }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tokenService,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        let tokenStatus = SecItemAdd(query as CFDictionary, nil)

        // Save server URL to Keychain (secure storage)
        let urlSaved = saveServerURL(serverURL)

        return tokenStatus == errSecSuccess && urlSaved
    }

    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tokenService,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        guard status == errSecSuccess, let data = dataTypeRef as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Server URL Storage (Secure)

    /// Saves the server URL into the Keychain
    /// - Parameter url: The server URL to save
    /// - Returns: True if save is successful, false otherwise
    @discardableResult
    func saveServerURL(_ url: URL) -> Bool {
        guard let data = url.absoluteString.data(using: .utf8) else { return false }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serverURLService,
            kSecValueData as String: data
        ]
        // Delete existing entry first
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func getServerURL() -> URL? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serverURLService,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let urlString = String(data: data, encoding: .utf8) else {
            return nil
        }
        return URL(string: urlString)
    }

    // MARK: - Deletion

    func deleteToken() {
        // Delete token from Keychain
        let tokenQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tokenService
        ]
        SecItemDelete(tokenQuery as CFDictionary)

        // Delete server URL from Keychain
        let urlQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serverURLService
        ]
        SecItemDelete(urlQuery as CFDictionary)

        // Clean up any legacy UserDefaults entries
        UserDefaults.standard.removeObject(forKey: legacyServerURLKey)
    }
} 
