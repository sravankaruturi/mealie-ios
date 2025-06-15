import SwiftUI

struct PasteboardImportBanner: View {
    let url: URL
    let onImport: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Text("Import recipe from \(url.host ?? url.absoluteString)?")
                .font(.subheadline)
            Spacer()
            Button("Import", action: onImport)
                .buttonStyle(.borderedProminent)
            Button("Dismiss", action: onDismiss)
                .buttonStyle(.bordered)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 4)
        .padding()
    }
} 