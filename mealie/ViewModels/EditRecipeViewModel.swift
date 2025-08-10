import Foundation
import SwiftUI
import SwiftData

@Observable
class EditRecipeViewModel {
    
    private let apiService: MealieAPIServiceProtocol
    private let recipe: Recipe
    private let user: User
    var modelContext: ModelContext
    
    var isLoading = false
    var error: String?
    var showSuccess = false
    
    // Editable fields
    var name: String
    var slug: String
    var description: String
    var prepTime: String
    var cookTime: String
    var performTime: String
    var servings: String
    var yield: String
    var orgURL: String
    var ingredients: [Ingredient]
    var instructions: [Instruction]
//    var photoImage: UIImage
    
    init(modelContext: ModelContext, recipe: Recipe, mealieAPIService: MealieAPIServiceProtocol, user: User) {
        self.modelContext = modelContext
        self.recipe = recipe
        self.user = user
        
        
        // Initialize editable fields with current recipe data
        self.name = recipe.name ?? ""
        self.slug = recipe.slug
        self.orgURL = recipe.orgUrl ?? ""
        self.description = recipe.recipeDescription
        self.prepTime = recipe.prepTime ?? ""
        self.cookTime = recipe.cookTime ?? ""
        self.performTime = recipe.performTime ?? ""
        self.servings = String(recipe.recipeServings)
        self.yield = recipe.recipeYield ?? ""
        self.ingredients = recipe.ingredients.sorted(by: { $0.orderIndex < $1.orderIndex })
        self.instructions = recipe.instructions
        self.apiService = mealieAPIService
        
    }
    
    func saveRecipe(isNew: Bool = false) async {
        
        isLoading = true
        error = nil
        
        // Declare all variables at the function level to avoid scope issues
        var recipeName: String = ""
        var recipeSlug: String = ""
        var recipeOrgURL: String?
        var cleanDescription: String = ""
        var cleanYield: String = ""
        var finalUserId: String = ""
        var finalGroupId: String = ""
        var finalHouseholdId: String = ""
        var dateAdded: String = ""
        var dateUpdated: String = ""
        var createdAt: String = ""
        var updateAt: String = ""
        var apiIngredients: [Components.Schemas.RecipeIngredient_hyphen_Input] = []
        var apiInstructions: [Components.Schemas.RecipeStep] = []
        
        do {
            // Debug logging
            print("🔧 EditRecipeViewModel: Starting recipe update for slug: \(recipe.slug)")
            print("🔧 EditRecipeViewModel: Recipe ID: \(recipe.remoteId)")
            print("🔧 EditRecipeViewModel: User ID: \(recipe.userId)")
            print("🔧 EditRecipeViewModel: Group ID: \(recipe.groupId)")
            print("🔧 EditRecipeViewModel: Household ID: \(recipe.houseHoldId)")
            print("🔧 EditRecipeViewModel: Name: \(name)")
            print("🔧 EditRecipeViewModel: Slug: \(slug)")
            print("🔧 EditRecipeViewModel: OrgURL: \(orgURL)")
            print("🔧 EditRecipeViewModel: Description: \(description)")
            print("🔧 EditRecipeViewModel: Servings: \(servings)")
            print("🔧 EditRecipeViewModel: Ingredients count: \(ingredients.count)")
            print("🔧 EditRecipeViewModel: Instructions count: \(instructions.count)")
            
            // Filter out empty ingredients and validate data
            let validIngredients = ingredients.filter { ingredient in
                !ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                // Removed quantity > 0 check as some ingredients might have 0 quantity but still be valid
            }
            
            let validInstructions = instructions.filter { instruction in
                !instruction.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            
            // Additional validation: clean ingredient names
            let cleanedIngredients = validIngredients.map { ingredient in
                var cleaned = ingredient
                // Remove any special characters or formatting that might cause issues
                cleaned.name = ingredient.name
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\n", with: " ")
                    .replacingOccurrences(of: "\r", with: " ")
                return cleaned
            }
            
            print("🔧 EditRecipeViewModel: Valid ingredients count: \(validIngredients.count)")
            print("🔧 EditRecipeViewModel: Valid instructions count: \(validInstructions.count)")
            
            // Ensure recipe name is not empty
            recipeName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Recipe" : name
            recipeSlug = slug.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? UUID().uuidString : slug
            recipeOrgURL = orgURL.isEmpty ? nil : orgURL
            
            // Clean up text fields to remove problematic characters
            cleanDescription = description
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: "\r", with: " ")
            
            cleanYield = yield
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: "\r", with: " ")
            
            finalUserId = !recipe.userId.isEmpty ? recipe.userId : user.id
            finalGroupId = recipe.groupId.isEmpty ? user.groupId : recipe.groupId
            finalHouseholdId = recipe.houseHoldId.isEmpty ? user.householdId : recipe.houseHoldId
            
            // Validate critical fields
            guard !finalUserId.isEmpty else {
                throw MealieAPIError.custom("User ID is required")
            }
            guard !finalGroupId.isEmpty else {
                throw MealieAPIError.custom("Group ID is required")
            }
            guard !finalHouseholdId.isEmpty else {
                throw MealieAPIError.custom("Household ID is required")
            }
            
            // Ensure date fields are properly formatted
            let currentDate = getDateStringForAPI(Date())
            dateAdded = recipe.dateAdded?.isEmpty == false ? recipe.dateAdded! : currentDate
            dateUpdated = currentDate
            createdAt = recipe.createdAt?.isEmpty == false ? recipe.createdAt! : currentDate
            updateAt = currentDate
            
            // Convert ingredients to API format
            apiIngredients = cleanedIngredients.map { ingredient in
                // Clean up the ingredient name by removing quantities and units from the name
                let cleanName = ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Try to match the unit with standard units, but be more conservative
                let unitName = ingredient.unit.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let standardUnit = IngredientUnit.matchUnit(unitName)
                
                // Only use fallback for clearly invalid units, preserve more original names
                let finalUnitName = if unitName.isEmpty || unitName == "to" {
                    "item"
                } else {
                    standardUnit.name
                }
                
                let unitPayload = Components.Schemas.RecipeIngredient_hyphen_Input.unitPayload(
                    value1: nil,
                    value2: Components.Schemas.CreateIngredientUnit(name: finalUnitName)
                )
                let foodPayload = Components.Schemas.RecipeIngredient_hyphen_Input.foodPayload(
                    value1: nil,
                    value2: Components.Schemas.CreateIngredientFood(name: cleanName)
                )
                return Components.Schemas.RecipeIngredient_hyphen_Input(
                    quantity: ingredient.quantity,
                    unit: unitPayload,
                    food: foodPayload,
                    note: ingredient.note,
                    isFood: nil,
                    disableAmount: true, // Changed from false to true to match schema default
                    display: ingredient.originalText,
                    title: ingredient.title,
                    originalText: ingredient.originalText,
                    referenceId: nil
                )
            }
            
            // Debug logging for ingredients
            print("🔧 EditRecipeViewModel: API Ingredients:")
            for (index, ingredient) in apiIngredients.enumerated() {
                print("    \(index): \(ingredient.food?.value2?.name ?? "Unknown") - \(ingredient.quantity) \(ingredient.unit?.value2?.name ?? "Unknown")")
            }
            
            // Debug logging for cleaned ingredients
            print("🔧 EditRecipeViewModel: Cleaned Ingredients:")
            for (index, ingredient) in cleanedIngredients.enumerated() {
                print("    \(index): \(ingredient.name) - \(ingredient.quantity) \(ingredient.unit.name)")
            }
            
            // Convert instructions to API format
            apiInstructions = validInstructions.map { instruction in
                Components.Schemas.RecipeStep(
                    id: nil,
                    title: instruction.title,
                    summary: nil,
                    text: instruction.text,
                    ingredientReferences: []
                )
            }
            
            // Debug logging for instructions
            print("🔧 EditRecipeViewModel: API Instructions:")
            for (index, instruction) in apiInstructions.enumerated() {
                print("    \(index): \(instruction.text ?? "No text")")
            }

            var remoteId = recipe.remoteId
            if isNew {
                let slug = try await apiService.addRecipeManual(recipeSlug: recipeSlug)
                print("🔧 EditRecipeViewModel: Recipe added with slug: \(slug)")
                let serverRecipe = try await apiService.fetchRecipeDetails(slug: slug)
                remoteId = serverRecipe.remoteId
            }
            
            // Create the recipe input data
            let recipeInput = Components.Schemas.Recipe_hyphen_Input(
                id: remoteId,
                userId: finalUserId,
                householdId: finalHouseholdId,
                groupId: finalGroupId,
                name: recipeName,
                slug: recipeSlug,
                image: recipe.image.flatMap { imageString in
                    // Only include image if it's not empty and is a valid string
                    let cleanImageString = imageString.trimmingCharacters(in: .whitespacesAndNewlines)
                    return cleanImageString.isEmpty ? nil : .init(stringLiteral: cleanImageString)
                },
                recipeServings: Double(servings) ?? 0,
                recipeYieldQuantity: Double(recipe.recipeYieldQuantity),
                recipeYield: cleanYield,
                totalTime: recipe.totalTime,
                prepTime: prepTime,
                cookTime: cookTime,
                performTime: performTime,
                description: cleanDescription,
                recipeCategory: [],
                tags: [],
                tools: [],
                rating: recipe.rating.map { Double($0) },
                orgURL: recipeOrgURL,
                dateAdded: dateAdded,
                dateUpdated: dateUpdated,
                createdAt: createdAt,
                update_at: updateAt,
                lastMade: recipe.lastMade,
                recipeIngredient: apiIngredients,
                recipeInstructions: apiInstructions,
                nutrition: nil,
                settings: nil,
                assets: [],
                notes: [],
                extras: .init(),
                comments: []
            )
            
            print("🔧 EditRecipeViewModel: About to call updateRecipe API...")
            
            // Debug: Log the final recipe data
            print("🔧 EditRecipeViewModel: Final recipe data:")
            print("    - ID: \(recipe.remoteId)")
            print("    - User ID: \(finalUserId)")
            print("    - Group ID: \(finalGroupId)")
            print("    - Household ID: \(finalHouseholdId)")
            print("    - Slug: \(recipeSlug)")
            print("    - OrgURL: \(recipeOrgURL ?? "NIL")")
            print("    - Name: \(recipeName)")
            print("    - Ingredients: \(apiIngredients.count)")
            print("    - Instructions: \(apiInstructions.count)")
                        
            // Update the recipe on the server
            try await apiService.updateRecipe(slug: recipeSlug, recipeData: recipeInput)
            
            print("🔧 EditRecipeViewModel: API call successful, updating local data...")
            
            // Update local recipe data
            recipe.name = recipeName
            recipe.recipeDescription = cleanDescription
            recipe.prepTime = prepTime
            recipe.cookTime = cookTime
            recipe.performTime = performTime
            recipe.recipeServings = Int(servings) ?? 0
            recipe.recipeYield = cleanYield
            recipe.ingredients = ingredients.enumerated().map { (index, ingredient) in
                var updated = ingredient
                updated.orderIndex = index
                return updated
            }
            recipe.instructions = instructions.enumerated().map { (index, instruction) in
                var updated = instruction
                updated.step = index + 1
                return updated
            }
            try? modelContext.save()
            showSuccess = true
            isLoading = false
            print("🔧 EditRecipeViewModel: Recipe update completed successfully")
        } catch {
            print("❌ EditRecipeViewModel: Error updating recipe: \(error)")
            print("❌ EditRecipeViewModel: Error type: \(type(of: error))")
            if let mealieError = error as? MealieAPIError {
                print("❌ EditRecipeViewModel: MealieAPIError case: \(mealieError)")
            }
            
            // Log the data that was being sent to help debug
            print("❌ EditRecipeViewModel: Failed to update recipe with data:")
            print("    - Name: \(recipeName)")
            print("    - Ingredients count: \(apiIngredients.count)")
            print("    - Instructions count: \(apiInstructions.count)")
            print("    - First ingredient: \(apiIngredients.first?.food?.value2?.name ?? "None")")
            print("    - First instruction: \(apiInstructions.first?.text ?? "None")")
            
            self.error = error.localizedDescription
            self.isLoading = false
        }
    }
    
    func addIngredient() {
        let newIngredient = Ingredient(orderIndex: ingredients.count, name: "", quantity: 0, unit: IngredientUnit(name: ""), originalText: "", note: "")
        ingredients.append(newIngredient)
    }
    func removeIngredient(at indexSet: IndexSet) {
        ingredients.remove(atOffsets: indexSet)
    }
    func moveIngredient(from source: IndexSet, to destination: Int) {
        ingredients.move(fromOffsets: source, toOffset: destination)
    }
    func addInstruction() {
        let newInstruction = Instruction(step: instructions.count + 1, text: "", title: "")
        instructions.append(newInstruction)
    }
    func removeInstruction(at indexSet: IndexSet) {
        instructions.remove(atOffsets: indexSet)
        instructions = instructions.enumerated().map { (index, instruction) in
            var updated = instruction
            updated.step = index + 1
            return updated
        }
    }
    func moveInstruction(from source: IndexSet, to destination: Int) {
        instructions.move(fromOffsets: source, toOffset: destination)
        instructions = instructions.enumerated().map { (index, instruction) in
            var updated = instruction
            updated.step = index + 1
            return updated
        }
    }
    func addInstructionSection() {
        // Find the next section number
        let sectionCount = instructions.compactMap { $0.title }.filter { !$0.isEmpty }.count + 1
        let newSectionTitle = "Section \(sectionCount)"
        let newStep = instructions.count + 1
        instructions.append(Instruction(step: newStep, text: "", title: newSectionTitle))
    }
    func removeInstruction(id: String?) {
        if let id = id, let idx = instructions.firstIndex(where: { $0.id == id }) {
            removeInstruction(at: IndexSet(integer: idx))
        }
    }
    
    func updateSlugBasedOnName() {
        
        self.slug = name.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "-").lowercased()
        
    }
}
