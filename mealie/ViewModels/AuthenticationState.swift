//
//  AuthenticationState.swift
//  mealie
//
//  Created by Sravan Karuturi on 6/15/25.
//
import SwiftUI
import Observation

@Observable
final class AuthenticationState {

    enum AuthStatus: Equatable {
        case unknown
        case authenticated(User)
        case unauthenticated
        case loading
        case sessionExpired  // New state for expired sessions

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

    private let keychainService: KeychainService
    private let authService: AuthenticationServiceProtocol

    /// Token for the session expiration observer - must be stored to properly remove observer
    private var sessionExpiredObserverToken: NSObjectProtocol?

    var status: AuthStatus = .unknown
    var isLoading: Bool = false

    /// Message to display when session expires
    var sessionExpiredMessage: String?

    var user: User? {
        switch status {
        case .authenticated(let user):
            return user
        default:
            return nil
        }
    }

    init(keychainService: KeychainService = .shared, authService: AuthenticationServiceProtocol) {

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

    /// Called when the API returns a 401 Unauthorized response
    @MainActor
    private func handleSessionExpired() {
        // Only handle if currently authenticated (avoid duplicate handling)
        guard case .authenticated = status else { return }

        print("🚫 AuthenticationState: Session expired, logging out user")

        // Clear credentials
        keychainService.deleteToken()

        // Update state to show session expired
        status = .sessionExpired
        sessionExpiredMessage = "Your session has expired. Please log in again."

        // Show toast notification
        ToastManager.shared.showWarning("Session expired. Please log in again.")
    }

    /// Clears the session expired message (call this after user acknowledges)
    @MainActor
    func clearSessionExpiredState() {
        if status == .sessionExpired {
            status = .unauthenticated
            sessionExpiredMessage = nil
        }
    }

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

    @MainActor
    func logout() {
        keychainService.deleteToken()
        status = .unauthenticated
    }

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
            keychainService.deleteToken()
            status = .unauthenticated
        }
    }
    
    var hasServerURLIssue: Bool {
        return keychainService.getToken() != nil && keychainService.getServerURL() == nil
    }
}
