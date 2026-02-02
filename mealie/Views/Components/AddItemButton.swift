import SwiftUI

/// A full-width button with a plus icon, used for adding items in edit forms.
///
/// Provides a consistent visual style across all "Add" actions in the recipe editor,
/// including adding ingredients, instruction steps, and sections.
struct AddItemButton: View {
    /// The label text displayed next to the plus icon.
    let title: String
    /// The action to perform when the button is tapped.
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBlue).opacity(0.15))
            .cornerRadius(16)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        AddItemButton(title: "Add Ingredient") {}
        AddItemButton(title: "Add Section") {}
        AddItemButton(title: "Add Step") {}
    }
    .padding()
}
