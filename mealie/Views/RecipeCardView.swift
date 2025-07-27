import SwiftUI
import Kingfisher

struct RecipeCardView: View {
    
    let recipe: Recipe
    @Environment(\.modelContext) private var modelContext
    @State private var isTogglingFavorite = false
    
    var mealieAPIService: MealieAPIServiceProtocol

    var body: some View {
        
        ZStack {
            // Recipe image using Kingfisher
            RecipeImageView(
                mealieAPIService: self.mealieAPIService,
                recipeId: recipe.apiId,
                imageType: .minOriginal, // Use medium size for cards
                placeholder: Image(systemName: "photo"),
                contentMode: .fill,
                cornerRadius: 8
            )
            .frame(width: 180, height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(recipe.name ?? "Untitled Recipe")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .fontWeight(.bold)
                        .lineLimit(2)
                        .shadow(radius: 4)
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await toggleFavorite()
                        }
                    }) {
                        Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(recipe.isFavorite ? .red : .gray)
                            .opacity(isTogglingFavorite ? 0.5 : 1.0)
                            .fontWeight(.bold)
                            .lineLimit(2)
                            .shadow(radius: 4)
                        
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isTogglingFavorite)
                }
                .padding(.all, 8)

                Spacer()
                
                HStack {
                    if let cookTime = recipe.cookTime {
                        Label(cookTime, systemImage: "flame")
                    }
                    Spacer()
                    Label("\(recipe.recipeServings)", systemImage: "person.2")
                }
                .font(.caption)
                .fontWeight(.bold)
                .padding(.all, 8)
//                .padding(.all, 4)
                .background(Color.white.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .clipped()
            }
        }
    }
    
    private func toggleFavorite() async {
        let slug = recipe.slug
        guard !slug.isEmpty else {
            print("Recipe slug is missing, cannot sync with server")
            // Still toggle locally even if server sync fails
            await MainActor.run {
                recipe.toggleFavorite()
                try? modelContext.save()
            }
            return
        }
        
        // Store the original state in case we need to revert
        let originalFavoriteState = recipe.isFavorite
        
        // Optimistic update - update UI immediately on main actor
        await MainActor.run {
            recipe.toggleFavorite()
            try? modelContext.save()
        }
        
        isTogglingFavorite = true
        
        do {
            if !recipe.isFavorite { // Note: we already toggled, so check the new state
                // Remove from favorites
                try await self.mealieAPIService.removeFromFavorites(recipeSlug: slug)
            } else {
                // Add to favorites
                try await self.mealieAPIService.addToFavorites(recipeSlug: slug)
            }
            
            // Server sync successful, no need to revert
            
        } catch {
            print("Failed to sync favorite with server: \(error)")
            
            // Revert the optimistic update on failure - ensure this happens on main actor
            await MainActor.run {
                recipe.isFavorite = originalFavoriteState
                try? modelContext.save()
            }
            
            // You could show user feedback here (toast, alert, etc.)
            // For now, we'll just print the error
        }
        
        isTogglingFavorite = false
    }
}

#Preview {
    let sampleRecipe = Recipe(
        remoteId: "sample-recipe-123",
        userId: "user-123",
        groupId: "group-123",
        houseHoldId: "household-123",
        name: "Delicious Spaghetti Carbonara",
        slug: "delicious-spaghetti-carbonara",
        image: "sample-image-url",
        recipeDescription: "A classic Italian pasta dish with eggs, cheese, pancetta, and black pepper. This creamy and flavorful recipe is perfect for a quick weeknight dinner.",
        recipeServings: 4,
        recipeYieldQuantity: 4,
        recipeYield: "4 servings",
        totalTime: "30 minutes",
        prepTime: "10 minutes",
        cookTime: "20 minutes",
        performTime: nil,
        rating: 5,
        orgUrl: "https://example.com/recipe",
        dateAdded: "2024-01-15",
        dateUpdated: "2024-01-15",
        createdAt: "2024-01-15",
        lastMade: nil,
        update_at: "2024-01-15",
        lastModified: Date(),
        isFavorite: false
    )
    
    let favoriteRecipe = Recipe(
        remoteId: "favorite-recipe-456",
        userId: "user-123",
        groupId: "group-123",
        houseHoldId: "household-123",
        name: "Chocolate Chip Cookies",
        slug: "chocolate-chip-cookies",
        image: "favorite-image-url",
        recipeDescription: "Soft and chewy chocolate chip cookies with a golden brown exterior and gooey chocolate chips throughout.",
        recipeServings: 24,
        recipeYieldQuantity: 24,
        recipeYield: "24 cookies",
        totalTime: "45 minutes",
        prepTime: "15 minutes",
        cookTime: "12 minutes",
        performTime: nil,
        rating: 5,
        orgUrl: "https://example.com/cookies",
        dateAdded: "2024-01-10",
        dateUpdated: "2024-01-10",
        createdAt: "2024-01-10",
        lastMade: nil,
        update_at: "2024-01-10",
        lastModified: Date(),
        isFavorite: true
    )
    
    let thirdRecipe = Recipe(
        remoteId: "third-recipe-789",
        userId: "user-123",
        groupId: "group-123",
        houseHoldId: "household-123",
        name: "Grilled Chicken Salad",
        slug: "grilled-chicken-salad",
        image: "https://demo.mealie.io/api/media/recipes/7e099149-4f76-449d-86c6-1e5d65e4e543/images/original.webp",
        recipeDescription: "Fresh mixed greens with grilled chicken breast, cherry tomatoes, cucumber, and a light vinaigrette dressing.",
        recipeServings: 2,
        recipeYieldQuantity: 2,
        recipeYield: "2 servings",
        totalTime: "25 minutes",
        prepTime: "15 minutes",
        cookTime: "10 minutes",
        performTime: nil,
        rating: 4,
        orgUrl: "https://example.com/salad",
        dateAdded: "2024-01-20",
        dateUpdated: "2024-01-20",
        createdAt: "2024-01-20",
        lastMade: nil,
        update_at: "2024-01-20",
        lastModified: Date(),
        isFavorite: false
    )
    
    let mockService = MockMealieAPIService()
    
    HStack(spacing: 16) {
        RecipeCardView(recipe: sampleRecipe, mealieAPIService: mockService)
        RecipeCardView(recipe: thirdRecipe, mealieAPIService: mockService)
    }
    .padding(.horizontal)
    .modelContainer(for: Recipe.self, inMemory: true)
    .frame(width: .infinity, height: 120)
}
