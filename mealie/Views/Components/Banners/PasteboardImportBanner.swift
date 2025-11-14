import SwiftUI

struct PasteboardImportBanner: View {
    let onImport: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Text("Import recipe link detected on your clipboard.")
                .font(.subheadline)
            Spacer()
            Button("Import", action: onImport)
                .buttonStyle(.borderedProminent)
            Button("Dismiss", action: onDismiss)
                .buttonStyle(.bordered)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .shadow(radius: 4)
        .padding()
    }
} 


#Preview {
    PasteboardImportBanner(onImport: {}, onDismiss: {})
}
