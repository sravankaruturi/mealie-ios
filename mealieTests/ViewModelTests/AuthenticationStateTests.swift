import Foundation
import SwiftData
import Testing
@testable import mealIO

@MainActor
struct AuthenticationStateTests {

    private func makeAuthState(
        token: String? = nil,
        serverURL: URL? = nil,
        shouldSucceed: Bool = true,
        modelContext: ModelContext? = nil
    ) -> (AuthenticationState, MockKeychainService, MockAuthenticationService) {
        let keychain = MockKeychainService()
        keychain.storedToken = token
        keychain.storedServerURL = serverURL
        let authService = MockAuthenticationService()
        authService.shouldSucceed = shouldSucceed
        let state = AuthenticationState(keychainService: keychain, authService: authService, modelContext: modelContext)
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

    // MARK: - Offline Auth Tests

    @Test
    func checkForExistingAuth_cachedUser_authenticatesImmediately() async {
        let ctx = makeTestModelContext()
        let cachedUser = User(id: "cached-user", email: "test@test.com", group: "g", household: "h", groupId: "gid", groupSlug: "gs", householdId: "hid", householdSlug: "hs")
        ctx.insert(cachedUser)
        try? ctx.save()

        let (state, _, authService) = makeAuthState(
            token: "valid-token",
            serverURL: URL(string: "https://mealie.example.com"),
            shouldSucceed: true,
            modelContext: ctx
        )
        await state.checkForExistingAuth()

        // Should authenticate immediately with the cached user
        if case .authenticated(let user) = state.status {
            #expect(user.id == "cached-user")
        } else {
            Issue.record("Expected .authenticated with cached user, got \(state.status)")
        }
    }

    @Test
    func checkForExistingAuth_networkError_keepsCachedUser() async {
        let ctx = makeTestModelContext()
        let cachedUser = User(id: "cached-user", email: "test@test.com", group: "g", household: "h", groupId: "gid", groupSlug: "gs", householdId: "hid", householdSlug: "hs")
        ctx.insert(cachedUser)
        try? ctx.save()

        let keychain = MockKeychainService()
        keychain.storedToken = "valid-token"
        keychain.storedServerURL = URL(string: "https://mealie.example.com")
        let authService = MockAuthenticationService()
        // Simulate a network error (not a 401 auth rejection)
        authService.shouldSucceed = false
        authService.validationError = URLError(.notConnectedToInternet)

        let state = AuthenticationState(keychainService: keychain, authService: authService, modelContext: ctx)
        // Init triggers checkForExistingAuth → finds cached user → authenticates →
        // background validates → network error → stays authenticated. Wait for completion.
        try? await Task.sleep(for: .milliseconds(500))

        // Should stay authenticated — network errors don't log out
        if case .authenticated = state.status {
            // Success — user is still authenticated
        } else {
            Issue.record("Expected .authenticated after network error, got \(state.status)")
        }
        // Token should NOT be deleted
        #expect(keychain.deleteTokenCallCount == 0)
    }

    @Test
    func checkForExistingAuth_authRejection_logsOut() async {
        let ctx = makeTestModelContext()
        let cachedUser = User(id: "cached-user", email: "test@test.com", group: "g", household: "h", groupId: "gid", groupSlug: "gs", householdId: "hid", householdSlug: "hs")
        ctx.insert(cachedUser)
        try? ctx.save()

        let keychain = MockKeychainService()
        keychain.storedToken = "expired-token"
        keychain.storedServerURL = URL(string: "https://mealie.example.com")
        let authService = MockAuthenticationService()
        // Simulate a 401 auth rejection
        authService.shouldSucceed = false
        authService.validationError = MealieAPIError.unauthorized

        let state = AuthenticationState(keychainService: keychain, authService: authService, modelContext: ctx)
        // Init already triggers checkForExistingAuth → finds cached user → authenticates →
        // background validates → gets 401 → logs out. Wait for the background task to complete.
        try? await Task.sleep(for: .milliseconds(500))

        // Should be logged out — server explicitly rejected the token
        #expect(state.status == .unauthenticated)
        // Token should be deleted
        #expect(keychain.deleteTokenCallCount >= 1)
        // Cached user should be cleared
        let remainingUsers = (try? ctx.fetch(FetchDescriptor<User>())) ?? []
        #expect(remainingUsers.isEmpty)
    }

    @Test
    func login_cachesUser() async throws {
        let ctx = makeTestModelContext()
        let (state, _, _) = makeAuthState(
            shouldSucceed: true,
            modelContext: ctx
        )

        try await state.login(
            username: "user",
            password: "pass",
            serverURL: URL(string: "https://mealie.example.com")!
        )

        // User should be cached in the model context
        let cachedUsers = (try? ctx.fetch(FetchDescriptor<User>())) ?? []
        #expect(cachedUsers.count == 1)
    }

    @Test
    func logout_clearsCachedUser() async throws {
        let ctx = makeTestModelContext()
        // Pre-populate a cached user
        let cachedUser = User(id: "cached-user", email: "test@test.com", group: "g", household: "h", groupId: "gid", groupSlug: "gs", householdId: "hid", householdSlug: "hs")
        ctx.insert(cachedUser)
        try? ctx.save()

        let (state, _, _) = makeAuthState(
            token: "token",
            serverURL: URL(string: "https://mealie.example.com"),
            shouldSucceed: true,
            modelContext: ctx
        )
        // First authenticate
        state.status = .authenticated(cachedUser)

        // Then logout
        state.logout()

        // Cached user should be cleared
        let remainingUsers = (try? ctx.fetch(FetchDescriptor<User>())) ?? []
        #expect(remainingUsers.isEmpty)
        #expect(state.status == .unauthenticated)
    }
}
