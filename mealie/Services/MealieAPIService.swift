import Foundation

enum MealieAPIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case unauthorized
    case insecureConnection
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid server URL."
        case .networkError(let err): return err.localizedDescription
        case .decodingError(let err): return "Failed to decode response: \(err.localizedDescription)"
        case .unauthorized: return "Unauthorized. Please check your credentials."
        case .insecureConnection: return "Insecure connection. Allow HTTP or self-signed certificate?"
        case .custom(let msg): return msg
        }
    }
}

final class MealieAPIService {
    
    private(set) var serverURL: URL
    private var session: URLSession
    
    init(serverURL: URL) {
        self.serverURL = serverURL
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Authentication
    func login(username: String, password: String) async throws -> String {
        let url = serverURL.appendingPathComponent("/api/auth/token")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let bodyString = "username=\(username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&password=\(password.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        request.httpBody = bodyString.data(using: .utf8)
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MealieAPIError.networkError(NSError(domain: "No HTTP response", code: 0))
            }
            if httpResponse.statusCode == 401 {
                throw MealieAPIError.unauthorized
            }
            if !(200...299).contains(httpResponse.statusCode) {
                throw MealieAPIError.networkError(NSError(domain: "HTTP error", code: httpResponse.statusCode))
            }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let token = json?["access_token"] as? String else {
                throw MealieAPIError.custom("No access_token in response.")
            }
            return token
        } catch let error as URLError {
            if error.code == .appTransportSecurityRequiresSecureConnection || error.code == .serverCertificateUntrusted {
                throw MealieAPIError.insecureConnection
            }
            throw MealieAPIError.networkError(error)
        } catch {
            throw MealieAPIError.networkError(error)
        }
    }
    
    // MARK: - Recipes
    func fetchAllRecipes(page: Int = 1, perPage: Int = 50) async throws -> [Recipe] {
        // GET /api/recipes
        // Handle pagination, transform JSON to Recipe models
        throw MealieAPIError.custom("Not implemented")
    }
    
    func fetchRecipeDetails(slug: String) async throws -> Recipe {
        // GET /api/recipes/{recipe_slug}
        // Transform JSON to Recipe model
        throw MealieAPIError.custom("Not implemented")
    }
    
    func addRecipeManual(recipeData: [String: Any]) async throws -> Recipe {
        // POST /api/recipes
        throw MealieAPIError.custom("Not implemented")
    }
    
    func addRecipeFromURL(url: URL) async throws -> Recipe {
        // POST /api/recipes/create-from-url
        throw MealieAPIError.custom("Not implemented")
    }
    
    // MARK: - Meal Plan
    func createMealPlanEntry(entryData: [String: Any]) async throws {
        // POST /api/meal-plans
        throw MealieAPIError.custom("Not implemented")
    }
    
    // MARK: - Delete
    func deleteRecipe(slug: String) async throws {
        // DELETE /api/recipes/{recipe_slug}
        throw MealieAPIError.custom("Not implemented")
    }
    
    // MARK: - Transformation Layer
    // Implement JSON -> SwiftData model transformation here
} 
