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

// MARK: - Session Expiration Notification

/// Notification posted when the API returns a 401 Unauthorized response,
/// indicating the session has expired and the user needs to re-authenticate.
extension Notification.Name {
    static let sessionExpired = Notification.Name("mealie.sessionExpired")
}

/// OpenAPI client middleware that attaches a Bearer token from the Keychain
/// and monitors responses for 401 session-expiration events.
struct AuthenticationMiddleware: ClientMiddleware {

    /// Intercepts every outgoing request to attach the stored Bearer token,
    /// and posts a `.sessionExpired` notification when a 401 is returned.
    func intercept(
        _ request: HTTPTypes.HTTPRequest,
        body: OpenAPIRuntime.HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPTypes.HTTPRequest, OpenAPIRuntime.HTTPBody?, URL) async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?)
    ) async throws -> (HTTPTypes.HTTPResponse, OpenAPIRuntime.HTTPBody?) {

        var request = request
        var didAttachToken = false

        if let accessToken = KeychainService.shared.getToken() {
            request.headerFields[values: .authorization] = .init(["Bearer \(accessToken)"])
            didAttachToken = true
            AppLogger.debug(.auth, "Added Bearer token for operation: \(operationID)")
        } else {
            AppLogger.warning(.auth, "No access token found for operation: \(operationID)")
        }

        let (response, responseBody) = try await next(request, body, baseURL)

        // Check for 401 Unauthorized - only trigger session expired if we actually sent a token
        // This prevents login failures (wrong password) from triggering session expiration
        if response.status.code == 401 && didAttachToken {
            AppLogger.warning(.auth, "Received 401 Unauthorized for operation: \(operationID) - session expired")
            // Post notification on main thread so UI can respond
            await MainActor.run {
                NotificationCenter.default.post(name: .sessionExpired, object: nil)
            }
        }

        return (response, responseBody)
    }

}
