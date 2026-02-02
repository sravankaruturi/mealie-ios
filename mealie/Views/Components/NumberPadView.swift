import SwiftUI

// MARK: - Number Pad View

/// Custom numeric keypad with fraction buttons, digit grid, operators, and a delete key.
///
/// Used by ingredient editors to enter quantities. Communicates user input
/// through `onKeyPress` and `onDelete` callbacks, leaving state management to the caller.
struct NumberPadView: View {
    /// Called when a key (digit, fraction, or operator) is pressed, passing the key's string value.
    let onKeyPress: (String) -> Void
    /// Called when the delete key is pressed.
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

/// A single keypad button with configurable title, background, and foreground colors.
struct KeypadButton: View {
    /// The text displayed on the button face.
    let title: String
    /// The button's background color.
    let backgroundColor: Color
    /// The button's text color. Defaults to `.primary`.
    let foregroundColor: Color
    /// The action to perform when the button is tapped.
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

#Preview {
    NumberPadView(
        onKeyPress: { key in print("Key: \(key)") },
        onDelete: { print("Delete") }
    )
    .padding()
}
