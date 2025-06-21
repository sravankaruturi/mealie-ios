import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let urlString = recipe.image, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
                    }
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12)
                }
                Text(recipe.name ?? "Untitled Recipe")
                    .font(.largeTitle)
                    .bold()
                HStack(spacing: 16) {
                    Label("\(recipe.recipeServings)", systemImage: "person.2")
                    Label(recipe.prepTime ?? "", systemImage: "timer")
                    Label(recipe.cookTime ?? "", systemImage: "flame")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ingredients")
                        .font(.headline)
                    ForEach(recipe.ingredients.sorted { $0.orderIndex < $1.orderIndex }) { ingredient in
                        Text("• \(ingredient.originalText)")
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Instructions")
                        .font(.headline)
                    ForEach(recipe.instructions.sorted { $0.step < $1.step }) { instruction in
                        HStack(alignment: .top) {
                            Text("\(instruction.step).")
                                .bold()
                            Text(instruction.text)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(recipe.name ?? "Recipe")
        .navigationBarTitleDisplayMode(.inline)
    }
} 
