import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    @State private var checkedIngredients: Set<Int> = []
    
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
                // NOTE: The Mealie web interface uses 'performTime' to display what is conceptually the "Cook Time".
                // We are matching that behavior here instead of using the 'cookTime' field.
                HStack(spacing: 16) {
                    Label("\(recipe.recipeServings)", systemImage: "person.2")
                    Label(recipe.prepTime ?? "", systemImage: "timer")
                    Label(recipe.performTime ?? "", systemImage: "flame")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                // Ingredients with inline section titles
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ingredients")
                        .font(.headline)
                    ForEach(recipe.ingredients.sorted { $0.orderIndex < $1.orderIndex }) { ingredient in
                        VStack(alignment: .leading, spacing: 2) {
                            if let title = ingredient.title, !title.isEmpty {
                                Text(title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .padding(.top, 8)
                            }
                            HStack {
                                Button(action: {
                                    if checkedIngredients.contains(ingredient.orderIndex) {
                                        checkedIngredients.remove(ingredient.orderIndex)
                                    } else {
                                        checkedIngredients.insert(ingredient.orderIndex)
                                    }
                                }) {
                                    Image(systemName: checkedIngredients.contains(ingredient.orderIndex) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(checkedIngredients.contains(ingredient.orderIndex) ? .blue : .gray)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Text(ingredient.originalText)
                                    .strikethrough(checkedIngredients.contains(ingredient.orderIndex))
                                    .foregroundColor(checkedIngredients.contains(ingredient.orderIndex) ? .secondary : .primary)
                            }
                        }
                    }
                }
                
                // Instructions with inline section titles
                VStack(alignment: .leading, spacing: 8) {
                    Text("Instructions")
                        .font(.headline)
                    ForEach(recipe.instructions.sorted { $0.step < $1.step }) { instruction in
                        VStack(alignment: .leading, spacing: 2) {
                            if let title = instruction.title, !title.isEmpty {
                                Text(title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .padding(.top, 8)
                            }
                            HStack(alignment: .top) {
                                Text("\(instruction.step).")
                                    .bold()
                                Text(instruction.text)
                            }
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

// MARK: - Supporting Types

struct IngredientSection {
    let sectionTitle: String?
    var ingredients: [Ingredient]
}

struct InstructionSection {
    let sectionTitle: String?
    var instructions: [Instruction]
} 
