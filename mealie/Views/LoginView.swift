import SwiftUI

struct LoginView: View {
    
    @Bindable private var viewModel = LoginViewModel()
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case server, username, password
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("Mealie for iOS")
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
            if let error = viewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            Text("By clicking continue, you agree to our Terms of Service and Privacy Policy.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
} 
