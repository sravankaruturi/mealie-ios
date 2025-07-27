import Foundation
import SwiftUI

@Observable
final class LoginViewModel {
    
    var authState: AuthenticationState
    var mealieAPIService: MealieAPIServiceProtocol
    
    var serverURL: String = ""
    var username: String = ""
    var password: String = ""
    var isLoading: Bool = false
    
    // NOTE: You'll need to implement the MealieAPIService and KeychainService
    // for this ViewModel to be fully functional.
    
    init(authState: AuthenticationState, mealieAPIService: MealieAPIServiceProtocol) {
        self.authState = authState
        self.mealieAPIService = mealieAPIService
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
        
        mealieAPIService.setURL(url)
        
        do {
            let token = try await mealieAPIService.login(username: username, password: password)
            authState.login(token: token, serverURL: url)
            ToastManager.shared.showSuccess("Login successful!")
        } catch {
            ToastManager.shared.showError(error.localizedDescription)
        }
    }
}
