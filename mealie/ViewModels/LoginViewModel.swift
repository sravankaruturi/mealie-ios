import Foundation
import SwiftUI

@Observable
final class LoginViewModel {
    
    var authState: AuthenticationState
    
    var serverURL: String = ""
    var username: String = ""
    var password: String = ""
    var isLoading: Bool = false
    
    init(authState: AuthenticationState) {
        self.authState = authState
    }
    
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
