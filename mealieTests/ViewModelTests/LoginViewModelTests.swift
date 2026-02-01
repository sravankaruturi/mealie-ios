import Foundation
import Testing
@testable import mealIO

@MainActor
@Suite(.serialized)
struct LoginViewModelTests {

    private func makeVM(shouldSucceed: Bool = true) -> (LoginViewModel, AuthenticationState) {
        let mockAuth = MockAuthenticationService()
        mockAuth.shouldSucceed = shouldSucceed
        let mockKeychain = MockKeychainService()
        let authState = AuthenticationState(
            keychainService: mockKeychain,
            authService: mockAuth
        )
        let vm = LoginViewModel(authState: authState)
        return (vm, authState)
    }

    // MARK: - URL Normalization

    @Test
    func authenticate_normalizesTrailingSlashes() async {
        let (vm, authState) = makeVM()
        vm.serverURL = "https://mealie.example.com//"
        vm.username = "user"
        vm.password = "pass"
        await vm.authenticate()
        // Should succeed without crashing
        if case .authenticated = authState.status {
            // Success
        } else {
            Issue.record("Expected .authenticated, got \(authState.status)")
        }
    }

    // MARK: - Invalid URL

    @Test
    func authenticate_invalidURL_showsError() async {
        ToastManager.shared.clearQueue()
        defer { ToastManager.shared.clearQueue() }
        let (vm, _) = makeVM()
        vm.serverURL = ""
        await vm.authenticate()
        // The toast should show an error about invalid URL
        #expect(ToastManager.shared.currentToast?.type == .error)
    }

    // MARK: - Successful Auth

    @Test
    func authenticate_success_delegatesToAuthState() async {
        let (vm, authState) = makeVM(shouldSucceed: true)
        vm.serverURL = "https://mealie.example.com"
        vm.username = "user"
        vm.password = "pass"
        await vm.authenticate()
        if case .authenticated = authState.status {
            // Success
        } else {
            Issue.record("Expected .authenticated after login")
        }
    }

    // MARK: - Failed Auth

    @Test
    func authenticate_failure_showsErrorToast() async {
        ToastManager.shared.clearQueue()
        defer { ToastManager.shared.clearQueue() }
        let (vm, _) = makeVM(shouldSucceed: false)
        vm.serverURL = "https://mealie.example.com"
        vm.username = "user"
        vm.password = "wrong"
        await vm.authenticate()
        #expect(ToastManager.shared.currentToast?.type == .error)
    }

    // MARK: - Loading State

    @Test
    func authenticate_togglesIsLoading() async {
        let (vm, _) = makeVM()
        vm.serverURL = "https://mealie.example.com"
        vm.username = "user"
        vm.password = "pass"
        await vm.authenticate()
        #expect(vm.isLoading == false)
    }
}
