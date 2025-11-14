import SwiftUI

struct ProfileView: View {
    @Environment(AuthenticationState.self) private var authState
    let recipesViewModel: RecipesViewModel
    
    var mealieAPIService: MealieAPIServiceProtocol
    
    @State private var currentUser: Components.Schemas.UserOut?
    @State private var isLoadingUser = false
    @State private var userError: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.accentColor)
                        
                        if let user = currentUser {
                            Text(user.fullName ?? user.username ?? "Unknown User")
                                .font(.title2)
                                .bold()
                            
                            let email = user.email
                            if email.isEmpty == false {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("Loading user info...")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Server Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Server Information")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            if let serverURL = KeychainService.shared.getServerURL() {
                                InfoRow(
                                    icon: "server.rack",
                                    title: "Server URL",
                                    value: serverURL.host ?? serverURL.absoluteString,
                                    subtitle: serverURL.absoluteString
                                )
                            }
                            
                            if let user = currentUser {
                                InfoRow(
                                    icon: "person",
                                    title: "Username",
                                    value: user.username ?? "Unknown"
                                )
                                
                                let id = user.id
                                if id.isEmpty == false {
                                    InfoRow(
                                        icon: "number",
                                        title: "User ID",
                                        value: String(id.prefix(8)) + "..."
                                    )
                                }
                            }
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Sync Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sync Information")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            InfoRow(
                                icon: "clock",
                                title: "Last Sync",
                                value: formatLastSyncTime()
                            )
                            
                            InfoRow(
                                icon: "doc.text",
                                title: "Recipes",
                                value: "\(recipesViewModel.recipes.count) recipes"
                            )
                            
                            if recipesViewModel.isSyncing {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundColor(.blue)
                                    Text("Syncing...")
                                        .foregroundColor(.blue)
                                    Spacer()
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Sync Actions
                    VStack(spacing: 12) {
                        Button(action: {
                            Task {
                                await recipesViewModel.syncRecipes()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Sync Recipes")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                        .disabled(recipesViewModel.isSyncing)
                        
                        Button(action: {
                            Task {
                                await recipesViewModel.forceSyncRecipes()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise.circle")
                                Text("Force Sync")
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .disabled(recipesViewModel.isSyncing)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Logout Button
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
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .task {
                await loadUserInfo()
            }
            .refreshable {
                await loadUserInfo()
            }
        }
    }
    
    private func loadUserInfo() async {
        guard !isLoadingUser else { return }
        
        isLoadingUser = true
        userError = nil
        
        do {
            currentUser = try await self.mealieAPIService.getCurrentUser()
        } catch {
            userError = error.localizedDescription
            print("Failed to load user info: \(error)")
        }
        
        isLoadingUser = false
    }
    
    private func formatLastSyncTime() -> String {
        guard let lastSync = recipesViewModel.lastSyncTime else {
            return "Never"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastSync, relativeTo: Date())
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    var subtitle: String?
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
} 
