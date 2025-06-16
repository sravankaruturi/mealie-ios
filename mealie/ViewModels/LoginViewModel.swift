import Foundation
import SwiftUI

@Observable
final class LoginViewModel {
    
    var authState: AuthenticationState
    
    var serverURL: String = ""
    var username: String = ""
    var password: String = ""
    var isLoading: Bool = false
    var error: String?
    
    // NOTE: You'll need to implement the MealieAPIService and KeychainService
    // for this ViewModel to be fully functional.
    
    init(authState: AuthenticationState) {
        self.authState = authState
    }
    
    func authenticate() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        // Normalize the server URL: trim whitespace and remove all trailing slashes
        let trimmedURLString = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        var normalizedURLString = trimmedURLString
        while normalizedURLString.hasSuffix("/") {
            normalizedURLString = String(normalizedURLString.dropLast())
        }
        
        guard let url = URL(string: normalizedURLString) else {
            error = "Invalid server URL."
            return
        }
        
        let api = MealieAPIService.shared
        api.setURL(url)
        
        do {
            let token = try await api.login(username: username, password: password)
            authState.login(token: token, serverURL: url)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
