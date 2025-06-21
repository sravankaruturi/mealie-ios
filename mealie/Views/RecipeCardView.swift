import SwiftUI
import Kingfisher

struct RecipeCardView: View {
    let recipe: Recipe
    @Environment(\.modelContext) private var modelContext
    @State private var isTogglingFavorite = false

    var body: some View {
        HStack(spacing: 16) {
            // Recipe image using Kingfisher
            RecipeImageView(
                recipeId: recipe.apiId,
                imageType: .minOriginal, // Use medium size for cards
                placeholder: Image(systemName: "photo"),
                contentMode: .fill,
                cornerRadius: 8
            )
            .frame(width: 80, height: 80)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(recipe.name ?? "Untitled Recipe")
                        .font(.headline)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await toggleFavorite()
                        }
                    }) {
                        Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(recipe.isFavorite ? .red : .gray)
                            .opacity(isTogglingFavorite ? 0.5 : 1.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isTogglingFavorite)
                }
                
                Text(recipe.recipeDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Spacer()
                
                HStack {
                    if let cookTime = recipe.cookTime {
                        Label(cookTime, systemImage: "flame")
                    }
                    Spacer()
                    Label("\(recipe.recipeServings) servings", systemImage: "person.2")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
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
                try await MealieAPIService.shared.removeFromFavorites(recipeSlug: slug)
            } else {
                // Add to favorites
                try await MealieAPIService.shared.addToFavorites(recipeSlug: slug)
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
