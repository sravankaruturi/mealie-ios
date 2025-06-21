import SwiftUI
import Kingfisher

struct RecipeCardView: View {
    let recipe: Recipe

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
                Text(recipe.name ?? "Untitled Recipe")
                    .font(.headline)
                    .lineLimit(2)
                
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
}
