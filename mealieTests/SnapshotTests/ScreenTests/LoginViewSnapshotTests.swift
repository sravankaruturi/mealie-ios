import XCTest
import SnapshotTesting
import SwiftUI
@testable import mealIO

@MainActor
final class LoginViewSnapshotTests: XCTestCase {

    func test_emptyForm() {
        let authState = AuthenticationState(
            keychainService: MockKeychainService(),
            authService: MockAuthenticationService()
        )
        authState.status = .unauthenticated
        let vm = LoginViewModel(authState: authState)
        let view = snapshotView(LoginBodyView(viewModel: vm))
        assertViewSnapshot(view)
    }

    func test_filledForm() {
        let authState = AuthenticationState(
            keychainService: MockKeychainService(),
            authService: MockAuthenticationService()
        )
        authState.status = .unauthenticated
        let vm = LoginViewModel(authState: authState)
        vm.serverURL = "https://mealie.example.com"
        vm.username = "chef@example.com"
        vm.password = "password123"
        let view = snapshotView(LoginBodyView(viewModel: vm))
        assertViewSnapshot(view)
    }

    func test_loadingState() {
        let authState = AuthenticationState(
            keychainService: MockKeychainService(),
            authService: MockAuthenticationService()
        )
        authState.status = .unauthenticated
        let vm = LoginViewModel(authState: authState)
        vm.serverURL = "https://mealie.example.com"
        vm.username = "chef@example.com"
        vm.password = "password123"
        vm.isLoading = true
        let view = snapshotView(LoginBodyView(viewModel: vm))
        assertViewSnapshot(view)
    }
}
