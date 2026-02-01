//
//  AuthenticationService.swift
//  mealie
//
//  Created by Sravan Karuturi on 8/8/25.
//

import Foundation


/// Concrete authentication service that delegates to the Mealie API.
final class AuthenticationService: AuthenticationServiceProtocol {

    private let mealieAPIService: MealieAPIServiceProtocol

    /// Creates an authentication service backed by the given API service.
    /// - Parameter mealieAPIService: The API service used for network calls.
    init(mealieAPIService: MealieAPIServiceProtocol) {
        self.mealieAPIService = mealieAPIService
    }

    /// Logs in by setting the server URL, authenticating, and fetching user details.
    /// - Parameters:
    ///   - username: The user's login name.
    ///   - password: The user's password.
    ///   - serverURL: The base URL of the Mealie server.
    /// - Returns: A tuple containing the access token and the authenticated `User`.
    func login(username: String, password: String, serverURL: URL) async throws -> (token: String, user: User) {
        mealieAPIService.setURL(serverURL)
        
        let token = try await mealieAPIService.login(username: username, password: password)
        let user = try await mealieAPIService.fetchUserDetails()
        
        return (token, user)
    }
    
    /// Validates the token by attempting to fetch user details.
    /// - Parameters:
    ///   - token: The authentication token to validate.
    ///   - serverURL: The base URL of the Mealie server.
    /// - Returns: The `User` profile if the token is valid.
    func validateToken(token: String, serverURL: URL) async throws -> User {
        mealieAPIService.setURL(serverURL)
        return try await mealieAPIService.fetchUserDetails()
    }
}
