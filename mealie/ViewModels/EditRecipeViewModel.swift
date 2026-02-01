import Foundation
import SwiftUI
import SwiftData

@Observable
/// Manages the editing state and server synchronization for a single recipe.
class EditRecipeViewModel {

    private let apiService: MealieAPIServiceProtocol
    private let recipe: Recipe
    private let user: User
    var modelContext: ModelContext

    /// Whether a save operation is in progress.
    var isLoading = false
    /// The most recent error message from a save attempt.
    var error: String?
    /// Whether the last save operation completed successfully.
    var showSuccess = false
    
    // Sheet presentation state
    var isPresentingSheet = false
    var selectedIngredient: Ingredient?
    
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
    
    var availableUnits: [Components.Schemas.IngredientUnit_hyphen_Output] = []
    var availableFoods: [Components.Schemas.IngredientFood_hyphen_Output] = []
    
    /// Creates an edit view model for the given recipe.
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
        
        Task {
            await fetchUnits()
            await fetchFoods()
        }
        
    }
    
    /// Validates, saves locally, and pushes changes to the Mealie server.
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
            AppLogger.debug(.recipes, "Starting recipe update for slug: \(recipe.slug)")
            AppLogger.debug(.recipes, "Recipe ID: \(recipe.remoteId)")
            AppLogger.debug(.recipes, "User ID: \(recipe.userId)")
            AppLogger.debug(.recipes, "Group ID: \(recipe.groupId)")
            AppLogger.debug(.recipes, "Household ID: \(recipe.houseHoldId)")
            AppLogger.debug(.recipes, "Name: \(name)")
            AppLogger.debug(.recipes, "Slug: \(slug)")
            AppLogger.debug(.recipes, "OrgURL: \(orgURL)")
            AppLogger.debug(.recipes, "Description: \(description)")
            AppLogger.debug(.recipes, "Servings: \(servings)")
            AppLogger.debug(.recipes, "Ingredients count: \(ingredients.count)")
            AppLogger.debug(.recipes, "Instructions count: \(instructions.count)")
            
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
            
            AppLogger.debug(.recipes, "Valid ingredients count: \(validIngredients.count)")
            AppLogger.debug(.recipes, "Valid instructions count: \(validInstructions.count)")
            
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
            
            apiIngredients = cleanedIngredients.map { ingredient in
                let cleanName = ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines)
                
                var unitPayload: Components.Schemas.RecipeIngredient_hyphen_Input.unitPayload?
                let unitNameLowercased = ingredient.unit.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

                // Find a matching unit from the fetched list
                if let matchedUnit = self.availableUnits.first(where: { $0.name.lowercased() == unitNameLowercased }) {
                    // If a match is found, use its ID to create the payload
                    unitPayload = .init(
                        value1: .init(id: matchedUnit.id, name: matchedUnit.name),
                        value2: nil
                    )
                } else {
                    // As a fallback, if no unit is matched, clear it
                    unitPayload = nil
                }
                
                var foodPayload: Components.Schemas.RecipeIngredient_hyphen_Input.foodPayload?
                let foodNameLowercased = cleanName.lowercased()

                // Try to find a matching, existing food item
                if let matchedFood = self.availableFoods.first(where: { $0.name.lowercased() == foodNameLowercased }) {
                    // SUCCESS: Match found. Use its ID.
                    foodPayload = .init(
                        value1: .init(id: matchedFood.id, name: matchedFood.name),
                        value2: nil
                    )
                } else {
                    foodPayload = nil
                }
                
                return Components.Schemas.RecipeIngredient_hyphen_Input(
                    quantity: ingredient.quantity,
                    unit: unitPayload, // Use the new, correctly structured payload
                    food: foodPayload,
                    note: ingredient.note,
                    disableAmount: true,
                    display: ingredient.originalText,
                    title: ingredient.title,
                    originalText: ingredient.originalText,
                    referenceId: nil
                )
            }
            
            // Debug logging for ingredients
            AppLogger.debug(.recipes, "API Ingredients:")
            for (index, ingredient) in apiIngredients.enumerated() {
                AppLogger.debug(.recipes, "  \(index): \(ingredient.food?.value2?.name ?? "Unknown") - \(ingredient.quantity) \(ingredient.unit?.value2?.name ?? "Unknown")")
            }

            // Debug logging for cleaned ingredients
            AppLogger.debug(.recipes, "Cleaned Ingredients:")
            for (index, ingredient) in cleanedIngredients.enumerated() {
                AppLogger.debug(.recipes, "  \(index): \(ingredient.name) - \(ingredient.quantity) \(ingredient.unit.name)")
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
            AppLogger.debug(.recipes, "API Instructions:")
            for (index, instruction) in apiInstructions.enumerated() {
                AppLogger.debug(.recipes, "  \(index): \(instruction.text ?? "No text")")
            }

            var remoteId = recipe.remoteId
            if isNew {
                let slug = try await apiService.addRecipeManual(recipeName: recipeName)
                AppLogger.debug(.recipes, "Recipe added with slug: \(slug)")
                let serverRecipe = try await apiService.fetchRecipeDetails(slug: slug)
                recipeSlug = serverRecipe.slug
                self.slug = serverRecipe.slug
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
            
            AppLogger.debug(.recipes, "About to call updateRecipe API...")

            // Debug: Log the final recipe data
            AppLogger.debug(.recipes, "Final recipe data:")
            AppLogger.debug(.recipes, "  - ID: \(recipe.remoteId)")
            AppLogger.debug(.recipes, "  - User ID: \(finalUserId)")
            AppLogger.debug(.recipes, "  - Group ID: \(finalGroupId)")
            AppLogger.debug(.recipes, "  - Household ID: \(finalHouseholdId)")
            AppLogger.debug(.recipes, "  - Slug: \(recipeSlug)")
            AppLogger.debug(.recipes, "  - OrgURL: \(recipeOrgURL ?? "NIL")")
            AppLogger.debug(.recipes, "  - Name: \(recipeName)")
            AppLogger.debug(.recipes, "  - Ingredients: \(apiIngredients.count)")
            AppLogger.debug(.recipes, "  - Instructions: \(apiInstructions.count)")
                        
            // Update the recipe on the server
            try await apiService.updateRecipe(slug: recipeSlug, recipeData: recipeInput)
            
            AppLogger.debug(.recipes, "API call successful, updating local data...")
            
            // Update local recipe data
            recipe.remoteId = remoteId
            recipe.slug = recipeSlug
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

            do {
                try modelContext.save()
                showSuccess = true
                AppLogger.info(.recipes, "Recipe update completed successfully")
            } catch {
                AppLogger.error(.recipes, "Failed to save recipe locally: \(error)")
                self.error = "Recipe updated on server but failed to save locally: \(error.localizedDescription)"
            }
            isLoading = false
        } catch {
            AppLogger.error(.recipes, "Error updating recipe: \(error)")
            AppLogger.error(.recipes, "Error type: \(type(of: error))")
            if let mealieError = error as? MealieAPIError {
                AppLogger.error(.recipes, "MealieAPIError case: \(mealieError)")
            }

            // Log high-level counts at error; move user content to debug-only
            AppLogger.error(.recipes, "Failed to update recipe (ingredients: \(apiIngredients.count), instructions: \(apiInstructions.count))")
            AppLogger.debug(.recipes, "Failed recipe name: \(recipeName)")
            AppLogger.debug(.recipes, "First ingredient: \(apiIngredients.first?.food?.value2?.name ?? "None")")
            AppLogger.debug(.recipes, "First instruction: \(apiInstructions.first?.text ?? "None")")
            
            self.error = error.localizedDescription
            self.isLoading = false
        }
    }
    
    /// Appends a new blank ingredient to the recipe.
    func addIngredient() {
        let newIngredient = Ingredient(orderIndex: ingredients.count, name: "", quantity: 0, unit: IngredientUnit(name: "Item"), originalText: "", note: "")
        selectedIngredient = newIngredient
        isPresentingSheet = true
    }
    
    /// Opens the ingredient edit sheet for the given ingredient.
    func editIngredient(_ ingredient: Ingredient) {
        selectedIngredient = ingredient
        isPresentingSheet = true
    }
    
    /// Saves changes from the ingredient edit sheet back to the recipe.
    func saveIngredient(_ ingredient: Ingredient) {
        
        // Since ingredients are now updated in place, we just need to handle new ingredients
        if !ingredients.contains(where: { $0.id == ingredient.id }) {
            // This is a new ingredient, add it
            ingredients.append(ingredient)
        }
        
        // Update order indices
        ingredients = ingredients.enumerated().map { (index, ingredient) in
            var updated = ingredient
            updated.orderIndex = index
            return updated
        }
        
        isPresentingSheet = false
        selectedIngredient = nil
    }
    
    /// Dismisses the ingredient edit sheet without saving.
    func cancelIngredientEdit() {
        isPresentingSheet = false
        selectedIngredient = nil
    }
    
    /// Removes ingredients at the given index set.
    func removeIngredient(at indexSet: IndexSet) {
        ingredients.remove(atOffsets: indexSet)
    }
    /// Reorders ingredients via drag-and-drop.
    func moveIngredient(from source: IndexSet, to destination: Int) {
        ingredients.move(fromOffsets: source, toOffset: destination)
    }
    /// Appends a new blank instruction step.
    func addInstruction() {
        let newInstruction = Instruction(step: instructions.count + 1, text: "", title: "")
        instructions.append(newInstruction)
    }
    /// Removes instructions at the given index set.
    func removeInstruction(at indexSet: IndexSet) {
        instructions.remove(atOffsets: indexSet)
        instructions = instructions.enumerated().map { (index, instruction) in
            var updated = instruction
            updated.step = index + 1
            return updated
        }
    }
    /// Reorders instructions via drag-and-drop.
    func moveInstruction(from source: IndexSet, to destination: Int) {
        instructions.move(fromOffsets: source, toOffset: destination)
        instructions = instructions.enumerated().map { (index, instruction) in
            var updated = instruction
            updated.step = index + 1
            return updated
        }
    }
    /// Appends a new section header instruction.
    func addInstructionSection() {
        // Find the next section number
        let sectionCount = instructions.compactMap { $0.title }.filter { !$0.isEmpty }.count + 1
        let newSectionTitle = "Section \(sectionCount)"
        let newStep = instructions.count + 1
        instructions.append(Instruction(step: newStep, text: "", title: newSectionTitle))
    }
    /// Removes a specific instruction by its ID.
    func removeInstruction(id: String?) {
        if let id = id, let idx = instructions.firstIndex(where: { $0.id == id }) {
            removeInstruction(at: IndexSet(integer: idx))
        }
    }
    
    /// Auto-generates a URL slug from the recipe name.
    func updateSlugBasedOnName() {
        
        self.slug = name.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "-").lowercased()
        
    }
    
    /// Loads available ingredient units from the server.
    private func fetchUnits() async {
        do {
            self.availableUnits = try await apiService.fetchAllUnits()
            AppLogger.info(.recipes, "Successfully fetched \(self.availableUnits.count) units.")
        } catch {
            self.error = "Failed to load units: \(error.localizedDescription)"
        }
    }
    
    /// Loads available ingredient foods from the server.
    private func fetchFoods() async {
        do {
            self.availableFoods = try await apiService.fetchAllFoods()
            AppLogger.info(.recipes, "Successfully fetched \(self.availableFoods.count) foods.")
        } catch {
            self.error = "Failed to load available foods: \(error.localizedDescription)"
        }
    }
}
