import Foundation
import Testing
@testable import mealIO

@MainActor
struct AuthenticationStateTests {

    private func makeAuthState(
        token: String? = nil,
        serverURL: URL? = nil,
        shouldSucceed: Bool = true
    ) -> (AuthenticationState, MockKeychainService, MockAuthenticationService) {
        let keychain = MockKeychainService()
        keychain.storedToken = token
        keychain.storedServerURL = serverURL
        let authService = MockAuthenticationService()
        authService.shouldSucceed = shouldSucceed
        let state = AuthenticationState(keychainService: keychain, authService: authService)
        return (state, keychain, authService)
    }

    // MARK: - login() Tests

    @Test
    func login_success_transitionsToAuthenticated() async throws {
        let (state, _, _) = makeAuthState()
        try await state.login(
            username: "user",
            password: "pass",
            serverURL: URL(string: "https://mealie.example.com")!
        )
        if case .authenticated = state.status {
            // Success
        } else {
            Issue.record("Expected .authenticated, got \(state.status)")
        }
    }

    @Test
    func login_failure_transitionsToUnauthenticated() async {
        let (state, _, _) = makeAuthState(shouldSucceed: false)
        do {
            try await state.login(
                username: "user",
                password: "wrong",
                serverURL: URL(string: "https://mealie.example.com")!
            )
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(state.status == .unauthenticated)
        }
    }

    @Test
    func login_setsIsLoadingFalseAfterCompletion() async {
        let (state, _, _) = makeAuthState()
        try? await state.login(
            username: "user",
            password: "pass",
            serverURL: URL(string: "https://mealie.example.com")!
        )
        #expect(state.isLoading == false)
    }

    // MARK: - logout() Tests

    @Test
    func logout_clearsCredentials() {
        let (state, keychain, _) = makeAuthState(
            token: "token",
            serverURL: URL(string: "https://mealie.example.com")
        )
        state.logout()
        #expect(state.status == .unauthenticated)
        #expect(keychain.deleteTokenCallCount >= 1)
    }

    // MARK: - checkForExistingAuth() Tests

    @Test
    func checkForExistingAuth_noToken_goesUnauthenticated() async {
        let (state, _, _) = makeAuthState(token: nil, serverURL: nil)
        await state.checkForExistingAuth()
        #expect(state.status == .unauthenticated)
    }

    @Test
    func checkForExistingAuth_validToken_authenticates() async {
        let (state, _, _) = makeAuthState(
            token: "valid-token",
            serverURL: URL(string: "https://mealie.example.com"),
            shouldSucceed: true
        )
        await state.checkForExistingAuth()
        if case .authenticated = state.status {
            // Success
        } else {
            Issue.record("Expected .authenticated, got \(state.status)")
        }
    }

    @Test
    func checkForExistingAuth_invalidToken_goesUnauthenticated() async {
        let (state, keychain, _) = makeAuthState(
            token: "expired-token",
            serverURL: URL(string: "https://mealie.example.com"),
            shouldSucceed: false
        )
        await state.checkForExistingAuth()
        #expect(state.status == .unauthenticated)
        #expect(keychain.deleteTokenCallCount >= 1)
    }

    // MARK: - Session Expiration Tests

    @Test
    func clearSessionExpiredState_resetsToUnauthenticated() async {
        let (state, _, _) = makeAuthState()
        // First authenticate, then expire
        try? await state.login(
            username: "user",
            password: "pass",
            serverURL: URL(string: "https://mealie.example.com")!
        )
        // Manually set to sessionExpired for testing
        state.status = .sessionExpired
        state.clearSessionExpiredState()
        #expect(state.status == .unauthenticated)
    }

    // MARK: - hasServerURLIssue Tests

    @Test
    func hasServerURLIssue_tokenButNoURL_returnsTrue() {
        let (state, _, _) = makeAuthState(token: "token", serverURL: nil)
        #expect(state.hasServerURLIssue == true)
    }

    @Test
    func hasServerURLIssue_bothPresent_returnsFalse() {
        let (state, _, _) = makeAuthState(
            token: "token",
            serverURL: URL(string: "https://mealie.example.com")
        )
        #expect(state.hasServerURLIssue == false)
    }
}
