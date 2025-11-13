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
            
            LinearGradient(
                gradient: Gradient(colors: [.black.opacity(0.6), .clear]),
                startPoint: .top,
                endPoint: .center
            )
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
                    if let cookTime = recipe.cookTime?.split(separator: " ").first {
                        Label(cookTime, systemImage: "flame")
                    }
                    Label("\(recipe.recipeServings)", systemImage: "person.2")
                }
                .font(.caption)
                .padding(.all, 8)
                .background(Color.white.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .clipped()
                .padding(.all, 8)
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
    
    let mockService = MockMealieAPIService()
    
    HStack(spacing: 16) {
        RecipeCardView(recipe: MockMealieAPIService.sampleRecipe, mealieAPIService: mockService)
        RecipeCardView(recipe: MockMealieAPIService.thirdRecipe, mealieAPIService: mockService)
    }
    .padding(.horizontal)
    .modelContainer(for: Recipe.self, inMemory: true)
    .frame(width: .infinity, height: 120)
}
