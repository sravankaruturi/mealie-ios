import SwiftUI

/// Lightweight wrapper that injects the `AuthenticationState` environment into `LoginBodyView`.
struct LoginView : View {
    
    @Environment(AuthenticationState.self) var authState
    
    var body: some View {
        LoginBodyView(viewModel: .init(authState: authState))
    }
    
}

/// The login form displaying server URL, username, and password fields with a continue button.
struct LoginBodyView: View {
    
    @State var viewModel: LoginViewModel
    @FocusState private var focusedField: Field?
    
    /// The text fields available for keyboard focus management.
    enum Field: Hashable {
        case server, username, password
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("Gourmet for Mealie")
                .font(.title)
                .bold()
            VStack(spacing: 16) {
                TextField("https://mealie.example.com", text: $viewModel.serverURL)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .server)
                    .textFieldStyle(.roundedBorder)
                TextField("contact@example.com", text: $viewModel.username)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .username)
                    .textFieldStyle(.roundedBorder)
                SecureField("********", text: $viewModel.password)
                    .textContentType(.password)
                    .focused($focusedField, equals: .password)
                    .textFieldStyle(.roundedBorder)
            }
            Button(action: {
                Task { await viewModel.authenticate() }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)
            
            Spacer()
//            Text("By clicking continue, you agree to our Terms of Service and Privacy Policy.")
//                .font(.footnote)
//                .foregroundColor(.secondary)
//                .multilineTextAlignment(.center)
        }
        .padding()
    }
} 
