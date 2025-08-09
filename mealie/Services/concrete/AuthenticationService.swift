//
//  AuthenticationService.swift
//  mealie
//
//  Created by Sravan Karuturi on 8/8/25.
//

import Foundation


final class AuthenticationService: AuthenticationServiceProtocol {
    
    private let mealieAPIService: MealieAPIServiceProtocol
    
    init(mealieAPIService: MealieAPIServiceProtocol) {
        self.mealieAPIService = mealieAPIService
    }
    
    func login(username: String, password: String, serverURL: URL) async throws -> (token: String, user: User) {
        mealieAPIService.setURL(serverURL)
        
        let token = try await mealieAPIService.login(username: username, password: password)
        let user = try await mealieAPIService.fetchUserDetails()
        
        return (token, user)
    }
    
    func validateToken(token: String, serverURL: URL) async throws -> User {
        mealieAPIService.setURL(serverURL)
        return try await mealieAPIService.fetchUserDetails()
    }
}
