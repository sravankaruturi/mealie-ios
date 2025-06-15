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
    
    var isLoggedIn: Bool = false
    private let keychainService: KeychainService

    init(keychainService: KeychainService = .shared) {
        self.keychainService = keychainService
        self.isLoggedIn = keychainService.getToken() != nil
    }

    func login(token: String) {
        keychainService.saveToken(token)
        isLoggedIn = true
    }

    func logout() {
        keychainService.deleteToken()
        isLoggedIn = false
    }
}
