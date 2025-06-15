import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let url = recipe.imageURL {
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
                Text(recipe.name)
                    .font(.largeTitle)
                    .bold()
                HStack(spacing: 16) {
                    Label("\(recipe.servings)", systemImage: "person.2")
                    Label(recipe.prepTime, systemImage: "timer")
                    Label(recipe.cookTime, systemImage: "flame")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ingredients")
                        .font(.headline)
                    ForEach(recipe.ingredients) { ingredient in
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
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
    }
} 