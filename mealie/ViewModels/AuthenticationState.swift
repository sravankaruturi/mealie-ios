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
        if let token = keychainService.getToken() {
            self.isLoggedIn = true
            // Set up the API service with the stored server URL
            if let serverURL = keychainService.getServerURL() {
                MealieAPIService.shared.setURL(serverURL)
            }
        }
    }

    func login(token: String, serverURL: URL) {
        keychainService.saveToken(token, serverURL: serverURL)
        MealieAPIService.shared.setURL(serverURL)
        isLoggedIn = true
    }

    func logout() {
        keychainService.deleteToken()
        isLoggedIn = false
    }
}
