import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

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
    
    public static let shared = MealieAPIService(serverURL: nil)
    
    private(set) var serverURL: URL?
    private var session: URLSession
    var client: Client?
    
    init(serverURL: URL?) {
        
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config)
        
        if serverURL != nil {
            setURL(serverURL!)
        }else {
            print("Server URL is Null")
        }

    }
    
    public func setURL(_ url: URL) {
        self.serverURL = url
        self.client = Client(
            serverURL: url,
            transport: URLSessionTransport(),
            middlewares: [AuthenticationMiddleware()]
        )
    }
    
    // MARK: - Authentication
    func login(username: String, password: String) async throws -> String {
        
        let requestBody = Components.Schemas.Body_get_token_api_auth_token_post(
            username: username,
            password: password,
            remember_me: true
        )
        
        let input = Operations.get_token_api_auth_token_post.Input(
            body: .urlEncodedForm(requestBody)
            )
        
        do {
            let output = try await client!.get_token_api_auth_token_post(input)
            
            switch output {
                
            case .ok(let response):
                let jsonResponse = try response.body.json
                
                guard let token = jsonResponse.access_token else {
                    throw MealieAPIError.custom("No access_token in response.")
                }
                return token
                
            case .unprocessableContent(let response):
                // Handle validation errors (422).
                // You can inspect 'response.body' for more details if needed.
                throw MealieAPIError.custom("Validation Error: \(response)")

            case .undocumented(let statusCode, _):
                // Handle any other status code not in the spec.
                if statusCode == 401 {
                    throw MealieAPIError.unauthorized
                } else {
                    throw MealieAPIError.networkError(NSError(domain: "HTTP error", code: statusCode))
                }
            }
        } catch let error as URLError {
            if error.code == .appTransportSecurityRequiresSecureConnection || error.code == .serverCertificateUntrusted {
                throw MealieAPIError.insecureConnection
            }
            throw MealieAPIError.networkError(error)
        } catch {
            // Catches decoding errors or other issues.
            throw MealieAPIError.networkError(error)
        }
    
    }
    
    // MARK: - Recipes
    func fetchAllRecipes(page: Int = 1, perPage: Int = 50) async throws -> [Recipe] {
        
        let input = Operations.get_all_api_recipes_get.Input(query: .init() )
        let output = try await self.client!.get_all_api_recipes_get(input)
        
        switch output {
        case .ok(let response):
            
            let paginationResponse = try response.body.json
            
            let recipeSummaries = paginationResponse.items
            
            var recipes: [Recipe] = []
            
            for recipeSummary in recipeSummaries {
                
                guard let slug = recipeSummary.slug else { continue }
                
                let recipe = try await fetchRecipeDetails(slug: slug)
                recipes.append(recipe)
                
            }
            
            
            return recipes
        default:
            throw MealieAPIError.custom("Failed to fetch recipes.")
        }
        
    }
    
    func fetchRecipeDetails(slug: String) async throws -> Recipe {
        // GET /api/recipes/{recipe_slug}
        let input = Operations.get_one_api_recipes__slug__get.Input(path: .init(slug: slug))
        let output = try await client!.get_one_api_recipes__slug__get(input)
        
        switch output {
        case .ok(let response):
            
            let data: Components.Schemas.Recipe_hyphen_Output = try response.body.json
            
            let recipe = Recipe(output: data)
            
            return recipe
            
        default:
            throw MealieAPIError.custom("Failed to fetch recipe details.")
        }
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
