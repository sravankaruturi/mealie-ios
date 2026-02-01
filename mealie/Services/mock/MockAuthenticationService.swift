import Foundation

/// Configurable mock authentication service for testing and previews.
class MockAuthenticationService: AuthenticationServiceProtocol {

    /// Whether operations should succeed. When `false`, throws `loginError`/`validationError` or `.unauthorized`.
    var shouldSucceed: Bool = true
    /// Custom error to throw on `login()`. Falls back to `.unauthorized` if nil and `shouldSucceed` is false.
    var loginError: Error?
    /// Custom error to throw on `validateToken()`. Falls back to `.unauthorized` if nil and `shouldSucceed` is false.
    var validationError: Error?
    /// Number of times `login()` has been called.
    var loginCallCount = 0
    /// Number of times `validateToken()` has been called.
    var validateCallCount = 0

    func login(username: String, password: String, serverURL: URL) async throws -> (token: String, user: User) {
        loginCallCount += 1
        if let error = loginError { throw error }
        if !shouldSucceed { throw MealieAPIError.unauthorized }
        return ("mockToken", User.sampleData)
    }

    func validateToken(token: String, serverURL: URL) async throws -> User {
        validateCallCount += 1
        if let error = validationError { throw error }
        if !shouldSucceed { throw MealieAPIError.unauthorized }
        return User.sampleData
    }
}
