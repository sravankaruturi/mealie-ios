//
//  MockAuthenticationService.swift
//  mealie
//
//  Created by Sravan Karuturi on 8/17/25.
//

import Foundation

class MockAuthenticationService : AuthenticationServiceProtocol {
    
    func login(username: String, password: String, serverURL: URL) async throws -> (token: String, user: User) {
        return ("mockToken", User.sampleData)
    }
    
    func validateToken(token: String, serverURL: URL) async throws -> User {
        return User.sampleData
    }
    
}
