import Foundation
import SwiftUI

@Observable
final class LoginViewModel {
    // FIX: Removed @Published property wrappers.
    // The @Observable macro automatically makes these properties observable.
    var serverURL: String = ""
    var username: String = ""
    var password: String = ""
    var isLoading: Bool = false
    var error: String?
    
    // NOTE: You'll need to implement the MealieAPIService and KeychainService
    // for this ViewModel to be fully functional.
    
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
        
        // This assumes you have an API service class set up.
        let api = MealieAPIService(serverURL: url)
        
        do {
            let token = try await api.login(username: username, password: password)
            // This assumes you have a keychain helper class.
            KeychainService.shared.saveToken(token)
            // You might want to add a success state here to trigger navigation.
        } catch {
            self.error = error.localizedDescription
        }
    }
}
