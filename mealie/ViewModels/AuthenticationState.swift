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

    enum AuthStatus {
        case unknown
        case authenticated(User)
        case unauthenticated
        case loading
    }
    
    
    
    private let keychainService: KeychainService
    private let authService: AuthenticationServiceProtocol
    
    var status: AuthStatus = .unknown
    var isLoading: Bool = false

    var isLoggedIn: Bool {
        switch status {
            case .authenticated:
            return true
        default:
            return false
        }
    }

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

        Task {
            await self.checkForExistingAuth()
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
