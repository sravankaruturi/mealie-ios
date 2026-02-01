import Foundation
import SwiftUI

@MainActor
@Observable
/// Manages login form state and authentication flow.
final class LoginViewModel {

    var authState: AuthenticationState

    /// The server URL entered by the user.
    var serverURL: String = ""
    /// The username entered by the user.
    var username: String = ""
    /// The password entered by the user.
    var password: String = ""
    /// Whether authentication is in progress.
    var isLoading: Bool = false
    
    /// Creates a login view model bound to the given authentication state.
    init(authState: AuthenticationState) {
        self.authState = authState
    }
    
    /// Validates inputs and attempts to authenticate with the server.
    func authenticate() async {
        isLoading = true
        defer { isLoading = false }
        
        // Normalize the server URL: trim whitespace and remove all trailing slashes
        let trimmedURLString = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        var normalizedURLString = trimmedURLString
        while normalizedURLString.hasSuffix("/") {
            normalizedURLString = String(normalizedURLString.dropLast())
        }
        
        guard let url = URL(string: normalizedURLString) else {
            ToastManager.shared.showError("Invalid server URL.")
            return
        }
        
        do {
            try await authState.login(username: username, password: password, serverURL: url)
            ToastManager.shared.showSuccess("Login successful!")
        } catch {
            ToastManager.shared.showError(error.localizedDescription)
        }
    }
}
