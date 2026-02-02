import SwiftUI

/// A styled section header for recipe ingredient or instruction groups.
///
/// Supports two visual styles:
/// - ``Style/detail``: Lighter style for read-only recipe detail views.
/// - ``Style/edit``: Bolder style for recipe edit forms.
struct RecipeSectionHeader: View {
    /// The section title text.
    let title: String

    /// The visual style to use. Defaults to ``Style/detail``.
    var style: Style = .detail

    /// Visual style preset for the header.
    enum Style {
        /// Lighter style for read-only detail views.
        case detail
        /// Bolder style for edit forms.
        case edit
    }

    var body: some View {
        switch style {
        case .detail:
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.top, 8)
        case .edit:
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .padding(.vertical, 4)
        }
    }
}

#Preview("Detail Style") {
    VStack(alignment: .leading, spacing: 12) {
        RecipeSectionHeader(title: "For the Sauce")
        RecipeSectionHeader(title: "For the Pasta")
    }
    .padding()
}

#Preview("Edit Style") {
    VStack(alignment: .leading, spacing: 12) {
        RecipeSectionHeader(title: "Preparation", style: .edit)
        RecipeSectionHeader(title: "Cooking", style: .edit)
    }
    .padding()
}
