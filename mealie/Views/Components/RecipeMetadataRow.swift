import SwiftUI

/// A horizontal row of recipe metadata labels (servings, prep time, cook time).
///
/// Each item is rendered as a `Label` with an SF Symbol icon. Callers apply their own
/// font, foreground color, and background styling — this component handles only the shared
/// `HStack`-of-`Label`s structure.
///
/// Use ``filtered(_:)`` to automatically strip items with empty values before display.
struct RecipeMetadataRow: View {
    /// The metadata items to display.
    let items: [MetadataItem]

    /// A single piece of recipe metadata with an icon and text.
    struct MetadataItem: Identifiable {
        /// Unique identifier for this item.
        let id = UUID()
        /// The SF Symbol name for the icon.
        let icon: String
        /// The display text (e.g., "4", "30 min").
        let value: String
    }

    /// Returns only items whose values are non-empty after trimming whitespace.
    ///
    /// Use this to avoid displaying labels for missing recipe fields (e.g., no cook time).
    static func filtered(_ items: [MetadataItem]) -> [MetadataItem] {
        items.filter { !$0.value.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var body: some View {
        HStack(spacing: 12) {
            ForEach(items) { item in
                Label(item.value, systemImage: item.icon)
            }
        }
    }
}

#Preview("Detail Style") {
    RecipeMetadataRow(items: RecipeMetadataRow.filtered([
        .init(icon: "person.2", value: "4"),
        .init(icon: "timer", value: "15 min"),
        .init(icon: "flame", value: "30 min"),
    ]))
    .font(.subheadline)
    .foregroundColor(.secondary)
    .padding()
}

#Preview("Card Style") {
    RecipeMetadataRow(items: RecipeMetadataRow.filtered([
        .init(icon: "flame", value: "30"),
        .init(icon: "person.2", value: "4"),
    ]))
    .font(.caption)
    .padding(.all, 8)
    .background(Color.white.opacity(0.8))
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .padding()
}

#Preview("With Empty Values") {
    RecipeMetadataRow(items: RecipeMetadataRow.filtered([
        .init(icon: "person.2", value: "4"),
        .init(icon: "timer", value: ""),
        .init(icon: "flame", value: "  "),
    ]))
    .font(.subheadline)
    .foregroundColor(.secondary)
    .padding()
}
