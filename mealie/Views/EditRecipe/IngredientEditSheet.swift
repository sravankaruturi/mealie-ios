import SwiftUI

// Placeholder for ingredient editing sheet
struct IngredientEditSheet: View {
    
    @Binding var ingredient: Ingredient
    var onSave: (Ingredient) -> Void
    var onCancel: () -> Void
    
    @State private var quantity: String = ""
    @State private var unit: IngredientUnit = IngredientUnit(name: "")
    @State private var name: String = ""
    @State private var editingField: EditingField = .quantity
    
    enum EditingField { case quantity, unit, name }
    
    let units: [IngredientUnit] = [
        IngredientUnit(name: "Item"),
        IngredientUnit(name: "Tablespoon"),
        IngredientUnit(name: "Teaspoon"),
        IngredientUnit(name: "Cup"),
        IngredientUnit(name: "ml"),
        IngredientUnit(name: "g"),
        IngredientUnit(name: "kg"),
        IngredientUnit(name: "oz"),
        IngredientUnit(name: "lb"),
        IngredientUnit(name: "bunch")
    ]
    let fractions = ["¼", "⅓", "½", "⅔", "¾"]
    let numbers = ["1","2","3","4","5","6","7","8","9","0"]
    
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
                HStack(spacing: 8) {
                    ForEach(fractions, id: \.self) { frac in
                        Button(frac) { quantity.append(frac) }
                            .ingredientPadButton()
                    }
                }
                .padding(.bottom, 2)
                HStack(spacing: 8) {
                    ForEach(["1","2","3"], id: \.self) { n in
                        Button(n) { quantity.append(n) }
                            .ingredientPadButton()
                    }
                }
                HStack(spacing: 8) {
                    ForEach(["4","5","6"], id: \.self) { n in
                        Button(n) { quantity.append(n) }
                            .ingredientPadButton()
                    }
                }
                HStack(spacing: 8) {
                    ForEach(["7","8","9"], id: \.self) { n in
                        Button(n) { quantity.append(n) }
                            .ingredientPadButton()
                    }
                }
                HStack(spacing: 8) {
                    Button("0") { quantity.append("0") }
                        .ingredientPadButton()
                    Button(".") { quantity.append(".") }
                        .ingredientPadButton()
                    Button("delete") { if !quantity.isEmpty { quantity.removeLast() } }
                        .ingredientPadButton(background: .red.opacity(0.15), foreground: .red)
                }
            } else if editingField == .unit {
                Picker("Unit", selection: $unit) {
                    ForEach(units) { u in
                        Text(u.name).tag(u)
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
    
    private func saveAndClose() {
        var updated = ingredient
        updated.quantity = Double(quantity) ?? 0
        updated.unit = unit
        updated.name = name
        onSave(updated)
    }
    
    private func goToNextField() {
        switch editingField {
        case .quantity: editingField = .unit
        case .unit: editingField = .name
        case .name: editingField = .quantity
        }
    }
}

extension View {
    func ingredientPadButton(background: Color = Color(.systemGray5), foreground: Color = .primary) -> some View {
        self
            .font(.title2)
            .frame(width: 56, height: 44)
            .background(background)
            .foregroundColor(foreground)
            .cornerRadius(12)
    }
}


