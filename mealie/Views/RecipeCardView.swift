import SwiftUI

struct RecipeCardView: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: 16) {
            // Placeholder image
            AsyncImage(url: recipe.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
            }
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(recipe.summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Spacer()
                
                HStack {
                    Label(recipe.cookTime, systemImage: "flame")
                    Spacer()
                    Label(recipe.servings, systemImage: "person.2")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}
