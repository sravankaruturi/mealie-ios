import SwiftUI

// Row-level helper functions for EditRecipeBodyView
extension EditRecipeBodyView {
    
    @ViewBuilder
    func ingredientRow(index: Int, ingredient: Ingredient) -> some View {
        HStack {
            Button(action: { viewModel.removeIngredient(at: IndexSet(integer: index)) }) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            }
            Button(action: { viewModel.editIngredient(ingredient) }) {
                HStack(spacing: 4) {
                    Text(String(ingredient.quantity))
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                    Text(ingredient.unit.name)
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                    Text(ingredient.name)
                        .foregroundColor(.primary)
                }
            }
            Spacer()
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .background(Color(.systemBackground))
    }
    
    @ViewBuilder
    func instructionRow(instruction: Instruction) -> some View {
        HStack(alignment: .top) {
            Button(action: { viewModel.removeInstruction(id: instruction.id) }) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            }
            Text("\(instruction.step).")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .leading)
            TextField("Instruction step", text: Binding(
                get: { instruction.text },
                set: { newValue in
                    if let idx = viewModel.instructions.firstIndex(where: { $0.id == instruction.id }) {
                        viewModel.instructions[idx].text = newValue
                    }
                }
            ), axis: .vertical)
            .textFieldStyle(.roundedBorder)
            .lineLimit(2...6)
            Spacer()
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .background(Color(.systemBackground))
    }
}
