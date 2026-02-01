//
//  AuthenticationState.swift
//  mealie
//
//  Created by Sravan Karuturi on 6/15/25.
//
import SwiftUI
import Observation

@Observable
/// Observable state machine managing user authentication lifecycle.
final class AuthenticationState {

    /// Possible authentication states.
    enum AuthStatus: Equatable {
        case unknown
        /// Logged in with user profile.
        case authenticated(User)
        /// Not logged in.
        case unauthenticated
        case loading
        /// Session expired, re-authentication needed.
        case sessionExpired

        static func == (lhs: AuthStatus, rhs: AuthStatus) -> Bool {
            switch (lhs, rhs) {
            case (.unknown, .unknown),
                 (.unauthenticated, .unauthenticated),
                 (.loading, .loading),
                 (.sessionExpired, .sessionExpired):
                return true
            case (.authenticated(let lhsUser), .authenticated(let rhsUser)):
                return lhsUser.id == rhsUser.id
            default:
                return false
            }
        }
    }

    private let keychainService: KeychainServiceProtocol
    private let authService: AuthenticationServiceProtocol

    /// Token for the session expiration observer - must be stored to properly remove observer
    private var sessionExpiredObserverToken: NSObjectProtocol?

    /// The current authentication status.
    var status: AuthStatus = .unknown
    /// Whether an authentication operation is in progress.
    var isLoading: Bool = false

    /// Message displayed when the session expires.
    var sessionExpiredMessage: String?

    /// The authenticated user, if available.
    var user: User? {
        switch status {
        case .authenticated(let user):
            return user
        default:
            return nil
        }
    }

    /// Creates the auth state and subscribes to session expiration notifications.
    init(keychainService: KeychainServiceProtocol = KeychainService.shared, authService: AuthenticationServiceProtocol) {

        self.keychainService = keychainService
        self.authService = authService

        // Listen for session expiration notifications
        // Store the token to properly remove the observer in deinit
        sessionExpiredObserverToken = NotificationCenter.default.addObserver(
            forName: .sessionExpired,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSessionExpired()
        }

        Task {
            await self.checkForExistingAuth()
        }
    }

    deinit {
        if let token = sessionExpiredObserverToken {
            NotificationCenter.default.removeObserver(token)
        }
    }

    // MARK: - Session Expiration Handling

    /// Handles session expiration by clearing credentials and updating state.
    @MainActor
    private func handleSessionExpired() {
        // Only handle if currently authenticated (avoid duplicate handling)
        guard case .authenticated = status else { return }

        AppLogger.warning(.auth, "Session expired, logging out user")

        // Clear credentials
        keychainService.deleteToken()

        // Update state to show session expired
        status = .sessionExpired
        sessionExpiredMessage = "Your session has expired. Please log in again."

        // Show toast notification
        ToastManager.shared.showWarning("Session expired. Please log in again.")
    }

    /// Resets session-expired state back to unauthenticated for re-login.
    @MainActor
    func clearSessionExpiredState() {
        if status == .sessionExpired {
            status = .unauthenticated
            sessionExpiredMessage = nil
        }
    }

    /// Authenticates the user and transitions to the authenticated state on success.
    @MainActor
    func login(username: String, password: String, serverURL: URL) async throws {
        isLoading = true
        defer {
            isLoading = false
        }
        status = .loading

        do {
            let (token, user) = try await authService.login(username: username, password: password, serverURL: serverURL)
            status = .authenticated(user)
        } catch {
            status = .unauthenticated
            throw error
        }
    }

    /// Clears all credentials and returns to unauthenticated state.
    @MainActor
    func logout() {
        keychainService.deleteToken()
        status = .unauthenticated
    }

    /// Checks for a stored token on launch and validates it with the server.
    @MainActor
    func checkForExistingAuth() async {

        guard let token = keychainService.getToken(), let serverURL = keychainService.getServerURL() else {
            status = .unauthenticated
            return
        }

        status = .loading
        isLoading = true
        defer {
            isLoading = false
        }

        do {
            let user = try await authService.validateToken(token: token, serverURL: serverURL)
            status = .authenticated(user)
        } catch {
            AppLogger.debug(.auth, "Token validation failed: \(error.localizedDescription)")
            keychainService.deleteToken()
            status = .unauthenticated
        }
    }
    
    /// Whether the last error was a URL-related issue (helps UI show server config).
    var hasServerURLIssue: Bool {
        return keychainService.getToken() != nil && keychainService.getServerURL() == nil
    }
}
