import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()
    private let service = "mealie.api.token"
    private let serverURLKey = "mealie.server.url"
    
    private init() {}
    
    func saveToken(_ token: String, serverURL: URL) -> Bool {
        guard let data = token.data(using: .utf8) else { return false }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        // Save server URL
        UserDefaults.standard.set(serverURL.absoluteString, forKey: serverURLKey)
        
        return status == errSecSuccess
    }
    
    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        guard status == errSecSuccess, let data = dataTypeRef as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func getServerURL() -> URL? {
        guard let urlString = UserDefaults.standard.string(forKey: serverURLKey) else { return nil }
        return URL(string: urlString)
    }
    
    func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)
        UserDefaults.standard.removeObject(forKey: serverURLKey)
    }
} 