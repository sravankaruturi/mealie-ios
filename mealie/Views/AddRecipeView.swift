import SwiftUI

struct AddRecipeView: View {
    @State private var showManualForm = false
    @State private var showURLSheet = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Button(action: { showManualForm = true }) {
                Text("Manual")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            Button(action: { showURLSheet = true }) {
                Text("From URL")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showManualForm) {
            ManualRecipeFormView()
        }
        .sheet(isPresented: $showURLSheet) {
            ImportRecipeFromURLView()
        }
    }
} 