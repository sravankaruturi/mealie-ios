//
//  AuthenticationServiceProtocol.swift
//  mealie
//
//  Created by Sravan Karuturi on 8/8/25.
//

import Foundation

protocol AuthenticationServiceProtocol {
    func login(username: String, password: String, serverURL: URL) async throws -> (token: String, user: User)
    func validateToken(token: String, serverURL: URL) async throws -> User
}
