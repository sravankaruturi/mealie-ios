//
//  KeychainTokenCredential.swift
//  mealie
//
//  Created by Sravan Karuturi on 6/16/25.
//


import OpenAPIURLSession
import OpenAPIRuntime
import HTTPTypes
import Foundation

/// An adapter that conforms to the Credential protocol.
/// Its job is to fetch the API token from our KeychainService
/// whenever the AuthenticatingMiddleware needs it.
//struct KeychainTokenCredential: Credential {
//
//    /// This function is called by the middleware before every authenticated API request.
//    func getToken(forRequest: HTTPRequest) async throws -> String? {
//        // Fetch the current token from the keychain.
//        return KeychainService.shared.getToken()
//    }
//}

struct AuthenticationMiddleware : ClientMiddleware {
    
    
    func intercept(_ request: HTTPTypes.HTTPRequest, body: OpenAPIRuntime.HTTPBody?, baseURL: URL, operationID: String, next: @Sendable (HTTPTypes.HTTPRequest, OpenAPIRuntime.HTTPBody?, URL) async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?)) async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?) {
        
        var request = request
        
        if let accessToken = KeychainService.shared.getToken() {
            request.headerFields[values: .authorization] = .init(["Bearer \(accessToken)"])
            print("🔐 AuthenticationMiddleware: Added Bearer token for operation: \(operationID)")
        } else {
            print("⚠️ AuthenticationMiddleware: No access token found for operation: \(operationID)")
        }
        
        return try await next(request, body, baseURL)
        
    }
    
}
