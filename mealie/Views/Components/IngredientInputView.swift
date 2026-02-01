//
//  IngredientInputView.swift
//  mealie
//
//  Created by Sravan Karuturi on 8/19/25.
//

import SwiftUI
import SwiftData

/// Sheet-based ingredient editor with a custom number pad, unit picker, and name field.
struct IngredientInputView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State var quantity: String
    @State var selectedUnit: String
    @State var itemName: String
    
    let originalIngredient: Ingredient? // This is used to update the ingredient if it already exists
    
    let availableUnits: [Components.Schemas.IngredientUnit_hyphen_Output]
    
    let onSave: (Ingredient) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.blue)
                
                Spacer()
                
                Button("Save") {
                    let ingredient = createIngredient()
                    onSave(ingredient)
                }
                .foregroundColor(.blue)
                
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            
            // Ingredient Display
            IngredientDisplayView(
                quantity: quantity,
                selectedUnit: selectedUnit,
                itemName: $itemName
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            
            // Unit Selection
            UnitSelectionView(selectedUnit: $selectedUnit)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            
            // Number Pad
            NumberPadView(
                onKeyPress: { key in
                    quantity += key
                },
                onDelete: {
                    if !quantity.isEmpty {
                        quantity.removeLast()
                    }
                }
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.white.opacity(0.95))
        .cornerRadius(20)
        .shadow(radius: 10)
    }
    
    /// Builds an `Ingredient` from the current field values, updating the original if provided.
    private func createIngredient() -> Ingredient {
        let quantityValue = Double(quantity) ?? 0.0
        let unit = IngredientUnit(name: selectedUnit)
        let originalText = "\(quantity) \(selectedUnit) \(itemName)"

        if let originalIngredient = originalIngredient {
            originalIngredient.name = itemName
            originalIngredient.quantity = quantityValue
            originalIngredient.unit = unit
            originalIngredient.originalText = originalText
            return originalIngredient
        } else {
            return Ingredient(
                orderIndex: 0, // Will be set by the view model
                name: itemName,
                quantity: quantityValue,
                unit: unit,
                originalText: originalText,
                note: ""
            )
        }
    }
}

// MARK: - Ingredient Display View
/// Displays the current quantity, unit, and an editable ingredient name.
struct IngredientDisplayView: View {
    let quantity: String
    let selectedUnit: String
    @Binding var itemName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .bottom, spacing: 4) {
                Text(quantity)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text(selectedUnit)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            
            TextField("Ingredient name", text: $itemName)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .textFieldStyle(PlainTextFieldStyle())
        }
    }
}

// MARK: - Unit Selection View
/// Horizontal scrollable chip picker for selecting a measurement unit.
struct UnitSelectionView: View {
    @Binding var selectedUnit: String
    
    private let units = [
        "Item", "Tablespoon", "Teaspoon", "Cup", "Milligrams", 
        "Grams", "Kilograms", "Pound", "Ounce"
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(units, id: \.self) { unit in
                    Button(unit) {
                        selectedUnit = unit
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        selectedUnit == unit 
                            ? Color.blue.opacity(0.3) 
                            : Color.indigo.opacity(0.2)
                    )
                    .foregroundColor(
                        selectedUnit == unit 
                            ? .blue 
                            : .primary
                    )
                    .cornerRadius(20)
                    .font(.system(size: 14, weight: .medium))
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Preview
#Preview {
    IngredientInputView(quantity: "1", selectedUnit: "Kg", itemName: "Chicken", originalIngredient: nil, availableUnits: [] ) { _ in }
        .padding()
        .background(Color.gray.opacity(0.1))
}
