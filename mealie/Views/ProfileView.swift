import SwiftUI

struct ProfileView: View {
    @Environment(AuthenticationState.self) private var authState
    
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
                
                Button(action: {
                    authState.logout()
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Logout")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Profile")
        }
    }
} 