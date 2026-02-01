//
//  AuthenticationServiceProtocol.swift
//  mealie
//
//  Created by Sravan Karuturi on 8/8/25.
//

import Foundation

/// Protocol for authentication operations (login, token validation).
protocol AuthenticationServiceProtocol {
    /// Authenticates against the given server and returns a token and user profile.
    /// - Parameters:
    ///   - username: The user's login name.
    ///   - password: The user's password.
    ///   - serverURL: The base URL of the Mealie server.
    /// - Returns: A tuple containing the access token and the authenticated `User`.
    func login(username: String, password: String, serverURL: URL) async throws -> (token: String, user: User)
    /// Validates an existing token by fetching user details from the server.
    /// - Parameters:
    ///   - token: The authentication token to validate.
    ///   - serverURL: The base URL of the Mealie server.
    /// - Returns: The `User` profile if the token is valid.
    func validateToken(token: String, serverURL: URL) async throws -> User
}
