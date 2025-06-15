import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.accentColor)
                Text("Profile & Settings")
                    .font(.title2)
                Spacer()
            }
            .padding()
            .navigationTitle("Profile")
        }
    }
} 