//
//  IngredientInputView.swift
//  mealie
//
//  Created by Sravan Karuturi on 8/19/25.
//

import SwiftUI

struct IngredientInputView: View {
    
    @State var quantity: String
    @State var selectedUnit: String
    @State var itemName: String
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar
            HStack {
                Button("Save") {
                    print("Save tapped")
                }
                .foregroundColor(.blue)
                
                Spacer()
                
                Button("Next") {
                    print("Next tapped")
                }
                .foregroundColor(.blue)
                
                Button("+") {
                    print("Add tapped")
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
}

// MARK: - Ingredient Display View
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

// MARK: - Number Pad View
struct NumberPadView: View {
    let onKeyPress: (String) -> Void
    let onDelete: () -> Void
    
    private let fractions = ["¼", "⅓", "½", "⅔", "¾"]
    private let numbers = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["0"]
    ]
    private let operators = ["/", "-", "."]
    
    var body: some View {
        VStack(spacing: 12) {
            // Fractions Row
            HStack(spacing: 12) {
                ForEach(fractions, id: \.self) { fraction in
                    KeypadButton(
                        title: fraction,
                        backgroundColor: .indigo.opacity(0.2),
                        action: { onKeyPress(fraction) }
                    )
                }
            }
            
            // Numbers Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(numbers.flatMap { $0 }, id: \.self) { number in
                    KeypadButton(
                        title: number,
                        backgroundColor: .green.opacity(0.2),
                        action: { onKeyPress(number) }
                    )
                }
            }
            
            // Bottom Row with Operators and Delete
            HStack(spacing: 12) {
                // Operators
                ForEach(operators, id: \.self) { op in
                    KeypadButton(
                        title: op,
                        backgroundColor: .blue.opacity(0.2),
                        action: { onKeyPress(op) }
                    )
                }
                
                // Delete Button
                KeypadButton(
                    title: "delete",
                    backgroundColor: .red.opacity(0.2),
                    foregroundColor: .red,
                    action: onDelete
                )
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Keypad Button
struct KeypadButton: View {
    let title: String
    let backgroundColor: Color
    let foregroundColor: Color
    let action: () -> Void
    
    init(
        title: String,
        backgroundColor: Color,
        foregroundColor: Color = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(foregroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(backgroundColor)
                .cornerRadius(12)
        }
    }
}

// MARK: - Preview
#Preview {
    IngredientInputView(quantity: "1", selectedUnit: "Kg", itemName: "Chicken")
        .padding()
        .background(Color.gray.opacity(0.1))
}
