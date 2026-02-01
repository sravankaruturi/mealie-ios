import Foundation
@testable import mealIO

/// In-memory mock of `KeychainServiceProtocol` for unit testing.
class MockKeychainService: KeychainServiceProtocol {
    var storedToken: String?
    var storedServerURL: URL?
    var deleteTokenCallCount = 0

    @discardableResult
    func saveToken(_ token: String, serverURL: URL) -> Bool {
        storedToken = token
        storedServerURL = serverURL
        return true
    }

    func getToken() -> String? { storedToken }

    @discardableResult
    func saveServerURL(_ url: URL) -> Bool {
        storedServerURL = url
        return true
    }

    func getServerURL() -> URL? { storedServerURL }

    func deleteToken() {
        deleteTokenCallCount += 1
        storedToken = nil
        storedServerURL = nil
    }
}
