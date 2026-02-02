import SwiftUI

/// A custom keypad-based sheet for editing an ingredient's quantity, unit, and name.
struct IngredientEditSheet: View {
    
    @Binding var ingredient: Ingredient
    let availableUnits: [Components.Schemas.IngredientUnit_hyphen_Output]
    var onSave: (Ingredient) -> Void
    var onCancel: () -> Void
    
    @State private var quantity: String = ""
    @State private var unit: IngredientUnit = IngredientUnit(name: "")
    @State private var name: String = ""
    @State private var editingField: EditingField = .quantity
    
    /// Tracks which ingredient field is currently being edited.
    enum EditingField { case quantity, unit, name }
    
//    let units: [IngredientUnit] = [
//        IngredientUnit(name: "Item"),
//        IngredientUnit(name: "Tablespoon"),
//        IngredientUnit(name: "Teaspoon"),
//        IngredientUnit(name: "Cup"),
//        IngredientUnit(name: "ml"),
//        IngredientUnit(name: "g"),
//        IngredientUnit(name: "kg"),
//        IngredientUnit(name: "oz"),
//        IngredientUnit(name: "lb"),
//        IngredientUnit(name: "bunch")
//    ]
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button("Save") {
                    saveAndClose()
                }
                .font(.headline)
                .foregroundColor(.blue)
                Spacer()
                Button("Next") {
                    goToNextField()
                }
                .font(.headline)
                .foregroundColor(.green)
            }
            .padding(.horizontal)
            
            Spacer(minLength: 0)
            
            // Large preview
            VStack(spacing: 4) {
                Text("\(quantity) \(unit.name) \(name)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.top, 8)
                Text("Edit \(editingField == .quantity ? "Quantity" : editingField == .unit ? "Unit" : "Name")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 8)
            
            // Custom number pad/unit picker
            if editingField == .quantity {
                NumberPadView(
                    onKeyPress: { key in quantity.append(key) },
                    onDelete: { if !quantity.isEmpty { quantity.removeLast() } }
                )
            } else if editingField == .unit {
                Picker("Unit", selection: $unit) {
                    ForEach(availableUnits, id: \.id) { u in
                        Text(u.name).tag(IngredientUnit(name: u.name))
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
            } else if editingField == .name {
                TextField("Ingredient name", text: $name)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .font(.title2)
                    .padding(.horizontal)
            }
            
            Spacer(minLength: 0)
            
            HStack {
                ForEach([EditingField.quantity, .unit, .name], id: \.self) { field in
                    Button(action: { editingField = field }) {
                        Text(field == .quantity ? "Quantity" : field == .unit ? "Unit" : "Name")
                            .fontWeight(editingField == field ? .bold : .regular)
                            .foregroundColor(editingField == field ? .blue : .primary)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(editingField == field ? Color.blue.opacity(0.1) : Color.clear)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            
            Button("Cancel", action: onCancel)
                .foregroundColor(.red)
                .padding(.top, 8)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .onAppear {
            quantity = String(ingredient.quantity)
            unit = ingredient.unit
            name = ingredient.name
        }
    }
    
    /// Applies the current quantity, unit, and name values and invokes the save callback.
    private func saveAndClose() {
        var updated = ingredient
        updated.quantity = Double(quantity) ?? 0
        updated.unit = unit
        updated.name = name
        onSave(updated)
    }
    
    /// Cycles the editing focus to the next field (quantity → unit → name → quantity).
    private func goToNextField() {
        switch editingField {
        case .quantity: editingField = .unit
        case .unit: editingField = .name
        case .name: editingField = .quantity
        }
    }
}


#Preview {
    IngredientEditSheet(
        ingredient: .constant(Ingredient.sampleIngredient),
        availableUnits: [],
        onSave: { updated in
            AppLogger.debug(.recipes, "Saved ingredient: \(updated.name)")
        },
        onCancel: {
            AppLogger.debug(.recipes, "Cancelled editing")
        }
    )
}


