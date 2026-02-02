import SwiftUI
import Kingfisher

/// A card-style view displaying a recipe's image, name, and a favorite toggle button.
struct RecipeCardView: View {

    let recipe: Recipe
    @Environment(\.modelContext) private var modelContext
    @State private var isTogglingFavorite = false

    var mealieAPIService: MealieAPIServiceProtocol
    /// Optional sync manager for enqueueing favorite toggles when offline.
    var syncManager: SyncManager?
    /// Optional network monitor for checking connectivity.
    var networkMonitor: NetworkMonitor?

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
                
                RecipeMetadataRow(items: RecipeMetadataRow.filtered([
                    .init(icon: "flame", value: recipe.cookTime?.split(separator: " ").first.map(String.init) ?? ""),
                    .init(icon: "person.2", value: recipe.recipeServings > 0 ? "\(recipe.recipeServings)" : ""),
                ]))
                .font(.caption)
                .padding(.all, 8)
                .background(Color.white.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .clipped()
                .padding(.all, 8)
            }
        }
    }
    
    /// Optimistically toggles favorite state locally, then syncs with the server.
    ///
    /// If offline or the API call fails, the local state is kept and a
    /// ``PendingOperation`` is enqueued for later sync instead of reverting.
    private func toggleFavorite() async {
        let slug = recipe.slug
        guard !slug.isEmpty else {
            AppLogger.warning(.recipes, "Recipe slug is missing, cannot sync with server")
            await MainActor.run {
                recipe.toggleFavorite()
                do {
                    try modelContext.save()
                } catch {
                    AppLogger.error(.recipes, "Failed to save favorite toggle locally: \(error)")
                    ToastManager.shared.showError("Failed to save changes locally")
                }
            }
            return
        }

        // Optimistic update — save locally immediately
        await MainActor.run {
            recipe.toggleFavorite()
            do {
                try modelContext.save()
            } catch {
                AppLogger.error(.recipes, "Failed to save optimistic favorite update: \(error)")
            }
        }

        isTogglingFavorite = true

        let isOnline = networkMonitor?.isConnected ?? true
        if isOnline {
            do {
                if !recipe.isFavorite {
                    try await self.mealieAPIService.removeFromFavorites(recipeSlug: slug)
                } else {
                    try await self.mealieAPIService.addToFavorites(recipeSlug: slug)
                }
            } catch {
                AppLogger.warning(.recipes, "Failed to sync favorite with server, enqueueing: \(error)")
                enqueueFavoriteSync(slug: slug, isFavorite: recipe.isFavorite)
            }
        } else {
            AppLogger.info(.recipes, "Offline — enqueueing favorite toggle for later sync")
            enqueueFavoriteSync(slug: slug, isFavorite: recipe.isFavorite)
        }

        isTogglingFavorite = false
    }

    /// Enqueues a favorite toggle for later synchronization.
    private func enqueueFavoriteSync(slug: String, isFavorite: Bool) {
        let payload = FavoritePayload(slug: slug, isFavorite: isFavorite)
        guard let payloadData = try? JSONEncoder().encode(payload) else { return }
        syncManager?.enqueueOperation(
            type: .toggleFavorite,
            entityId: recipe.remoteId,
            payload: payloadData
        )
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
