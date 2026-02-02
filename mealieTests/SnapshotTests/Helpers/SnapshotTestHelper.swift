import XCTest
import SwiftUI
import SwiftData
import SnapshotTesting
@testable import mealIO

// MARK: - Device Configuration

/// iPhone 16 device configuration for snapshot tests.
let iPhone16Config = ViewImageConfig(
    safeArea: UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0),
    size: CGSize(width: 393, height: 852),
    traits: UITraitCollection(traitsFrom: [
        UITraitCollection(displayScale: 3),
        UITraitCollection(userInterfaceStyle: .light)
    ])
)

// MARK: - Snapshot Directory

/// Project root path, computed from this file's location.
private let projectRoot: String = {
    let thisFile = URL(fileURLWithPath: #filePath)
    return thisFile
        .deletingLastPathComponent() // Helpers
        .deletingLastPathComponent() // SnapshotTests
        .deletingLastPathComponent() // mealieTests
        .deletingLastPathComponent() // project root
        .path
}()

// MARK: - Snapshot Test Helper

extension XCTestCase {

    // MARK: - View Wrapping

    /// Wraps a view with all required environment objects for snapshot testing.
    func snapshotView<V: View>(
        _ view: V,
        authStatus: AuthenticationState.AuthStatus = .unauthenticated,
        isConnected: Bool = true,
        modelContext: ModelContext? = nil
    ) -> some View {
        let keychain = MockKeychainService()
        let authService = MockAuthenticationService()
        let authState = AuthenticationState(
            keychainService: keychain,
            authService: authService
        )
        authState.status = authStatus

        let monitor = NetworkMonitor()
        monitor.isConnected = isConnected

        let ctx = modelContext ?? makeTestModelContext()

        return view
            .environment(authState)
            .environment(monitor)
            .environment(ToastManager.shared)
            .environment(\.syncManager, nil)
            .modelContext(ctx)
    }

    /// Creates an `AuthenticationState` in the `.authenticated` state.
    func makeAuthenticatedState() -> AuthenticationState {
        let keychain = MockKeychainService()
        keychain.storedToken = "snapshot-test-token"
        keychain.storedServerURL = URL(string: "https://example.com")
        let authService = MockAuthenticationService()
        let authState = AuthenticationState(
            keychainService: keychain,
            authService: authService
        )
        authState.status = .authenticated(User.sampleData)
        return authState
    }

    // MARK: - Snapshot Directory per Class

    /// Returns a snapshot directory scoped to the current test class name.
    /// This ensures each class gets its own subdirectory under `__Snapshots__/`
    /// at the project root, avoiding filename collisions between classes.
    private var classSnapshotDirectory: String {
        let className = String(describing: type(of: self))
        return projectRoot + "/__Snapshots__/" + className
    }

    // MARK: - Assertion Helpers

    /// Asserts a full-screen snapshot of a view rendered on the iPhone 16 device config.
    /// Snapshots are saved to `__Snapshots__/<ClassName>/` at the project root.
    func assertViewSnapshot<V: View>(
        _ view: V,
        named name: String? = nil,
        record recording: Bool = false,
        precision: Float = 0.99,
        perceptualPrecision: Float = 0.98,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let vc = UIHostingController(rootView: view)
        let failure = verifySnapshot(
            of: vc,
            as: .image(on: iPhone16Config, precision: precision, perceptualPrecision: perceptualPrecision),
            named: name,
            record: recording,
            snapshotDirectory: classSnapshotDirectory,
            file: file,
            testName: testName,
            line: line
        )
        if let failure {
            XCTFail(failure, file: file, line: line)
        }
    }

    /// Asserts a component snapshot at a fixed size without device chrome.
    /// Snapshots are saved to `__Snapshots__/<ClassName>/` at the project root.
    func assertComponentSnapshot<V: View>(
        _ view: V,
        size: CGSize,
        named name: String? = nil,
        record recording: Bool = false,
        precision: Float = 0.99,
        perceptualPrecision: Float = 0.98,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let sized = view.frame(width: size.width, height: size.height)
        let vc = UIHostingController(rootView: sized)
        vc.view.frame = CGRect(origin: .zero, size: size)
        let failure = verifySnapshot(
            of: vc,
            as: .image(precision: precision, perceptualPrecision: perceptualPrecision, size: size),
            named: name,
            record: recording,
            snapshotDirectory: classSnapshotDirectory,
            file: file,
            testName: testName,
            line: line
        )
        if let failure {
            XCTFail(failure, file: file, line: line)
        }
    }

    // MARK: - Trait Helpers

    /// Returns a trait collection with dark mode applied on top of the given traits.
    func darkMode(_ traits: UITraitCollection) -> UITraitCollection {
        UITraitCollection(traitsFrom: [
            traits,
            UITraitCollection(userInterfaceStyle: .dark)
        ])
    }
}
