import Foundation

/// Protocol abstracting Keychain operations for dependency injection and testability.
protocol KeychainServiceProtocol {
    /// Saves an authentication token and server URL to the Keychain.
    @discardableResult
    func saveToken(_ token: String, serverURL: URL) -> Bool
    /// Retrieves the stored authentication token.
    func getToken() -> String?
    /// Saves the server URL to the Keychain.
    @discardableResult
    func saveServerURL(_ url: URL) -> Bool
    /// Retrieves the stored server URL.
    func getServerURL() -> URL?
    /// Removes all stored credentials from the Keychain.
    func deleteToken()
}
