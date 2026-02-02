import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
/// Manages the editing state and server synchronization for a single recipe.
class EditRecipeViewModel {

    private let apiService: MealieAPIServiceProtocol
    private let recipe: Recipe
    private let user: User
    var modelContext: ModelContext

    /// Optional sync manager for enqueueing operations when offline.
    var syncManager: SyncManager?
    /// Optional network monitor for checking connectivity before API calls.
    var networkMonitor: NetworkMonitor?

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
    
    /// Validates, saves locally first, then attempts to push changes to the Mealie server.
    ///
    /// If the device is offline or the API call fails, the local changes are preserved
    /// and a ``PendingOperation`` is enqueued for later synchronization.
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
            AppLogger.debug(.recipes, "Starting recipe save for slug: \(recipe.slug)")

            // Filter out empty ingredients and validate data
            let validIngredients = ingredients.filter { ingredient in
                !ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }

            let validInstructions = instructions.filter { instruction in
                !instruction.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }

            // Additional validation: clean ingredient names
            let cleanedIngredients = validIngredients.map { ingredient in
                var cleaned = ingredient
                cleaned.name = ingredient.name
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\n", with: " ")
                    .replacingOccurrences(of: "\r", with: " ")
                return cleaned
            }

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

                if let matchedUnit = self.availableUnits.first(where: { $0.name.lowercased() == unitNameLowercased }) {
                    unitPayload = .init(
                        value1: .init(id: matchedUnit.id, name: matchedUnit.name),
                        value2: nil
                    )
                } else {
                    unitPayload = nil
                }

                var foodPayload: Components.Schemas.RecipeIngredient_hyphen_Input.foodPayload?
                let foodNameLowercased = cleanName.lowercased()

                if let matchedFood = self.availableFoods.first(where: { $0.name.lowercased() == foodNameLowercased }) {
                    foodPayload = .init(
                        value1: .init(id: matchedFood.id, name: matchedFood.name),
                        value2: nil
                    )
                } else {
                    foodPayload = nil
                }

                return Components.Schemas.RecipeIngredient_hyphen_Input(
                    quantity: ingredient.quantity,
                    unit: unitPayload,
                    food: foodPayload,
                    note: ingredient.note,
                    disableAmount: true,
                    display: ingredient.originalText,
                    title: ingredient.title,
                    originalText: ingredient.originalText,
                    referenceId: nil
                )
            }

            apiInstructions = validInstructions.map { instruction in
                Components.Schemas.RecipeStep(
                    id: nil,
                    title: instruction.title,
                    summary: nil,
                    text: instruction.text,
                    ingredientReferences: []
                )
            }

            // ─── LOCAL-FIRST: Save to SwiftData immediately ───

            var remoteId = recipe.remoteId

            // For new recipes that need server creation, we must be online
            if isNew {
                guard networkMonitor?.isConnected ?? true else {
                    throw MealieAPIError.custom("Creating new recipes requires an internet connection")
                }
                let slug = try await apiService.addRecipeManual(recipeName: recipeName)
                AppLogger.debug(.recipes, "Recipe added with slug: \(slug)")
                let serverRecipe = try await apiService.fetchRecipeDetails(slug: slug)
                recipeSlug = serverRecipe.slug
                self.slug = serverRecipe.slug
                remoteId = serverRecipe.remoteId
            }

            // Save locally first (optimistic update)
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
            recipe.hasLocalChanges = true

            do {
                try modelContext.save()
                AppLogger.info(.recipes, "Recipe saved locally")
            } catch {
                AppLogger.error(.recipes, "Failed to save recipe locally: \(error)")
                self.error = "Failed to save recipe locally: \(error.localizedDescription)"
                isLoading = false
                return
            }

            // ─── SYNC: Attempt API push ───

            let isOnline = networkMonitor?.isConnected ?? true

            if isOnline && !isNew {
                // Build the API payload
                let recipeInput = Components.Schemas.Recipe_hyphen_Input(
                    id: remoteId,
                    userId: finalUserId,
                    householdId: finalHouseholdId,
                    groupId: finalGroupId,
                    name: recipeName,
                    slug: recipeSlug,
                    image: recipe.image.flatMap { imageString in
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

                do {
                    try await apiService.updateRecipe(slug: recipeSlug, recipeData: recipeInput)
                    recipe.hasLocalChanges = false
                    try? modelContext.save()
                    AppLogger.info(.recipes, "Recipe synced to server successfully")
                } catch {
                    // API failed — enqueue for later sync
                    AppLogger.warning(.recipes, "API update failed, enqueueing for later: \(error.localizedDescription)")
                    enqueueRecipeSync(slug: recipeSlug)
                }
            } else if !isNew {
                // Offline — enqueue for later sync
                AppLogger.info(.recipes, "Offline — enqueueing recipe update for later sync")
                enqueueRecipeSync(slug: recipeSlug)
            }

            // For new recipes, the API calls already happened above, so clear the flag
            if isNew {
                recipe.hasLocalChanges = false
                try? modelContext.save()
            }

            showSuccess = true
            isLoading = false
        } catch {
            AppLogger.error(.recipes, "Error saving recipe: \(error)")
            if let mealieError = error as? MealieAPIError {
                AppLogger.error(.recipes, "MealieAPIError case: \(mealieError)")
            }

            AppLogger.error(.recipes, "Failed to save recipe (ingredients: \(apiIngredients.count), instructions: \(apiInstructions.count))")

            self.error = error.localizedDescription
            self.isLoading = false
        }
    }

    /// Enqueues a recipe update operation for later synchronization.
    private func enqueueRecipeSync(slug: String) {
        syncManager?.enqueueOperation(
            type: .updateRecipe,
            entityId: recipe.remoteId,
            payload: slug.data(using: .utf8)
        )
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
