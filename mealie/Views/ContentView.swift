import SwiftUI
import SwiftData
import UIKit

/// Root view that switches between login, loading, and the main tab interface based on authentication state.
struct ContentView: View {
    @State private var showPasteboardBanner = false
    @State private var lastPasteboardChangeCount: Int = -1

    /// The API service passed down to child views.
    var mealieAPIService: MealieAPIServiceProtocol
    /// The shared authentication state driving the view hierarchy.
    var authState: AuthenticationState
    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            
            switch authState.status {
            case .unknown:
                LoadingView()
            case .authenticated:
                MainTabView(mealieAPIService: mealieAPIService)
            case .unauthenticated:
                LoginView()
            case .loading:
                LoadingView()
            case .sessionExpired:
                // Show login view - the toast already notified the user
                LoginView()
                    .onAppear {
                        // Clear the expired state after showing login
                        authState.clearSessionExpiredState()
                    }
            }
            
            banners
            
        }
        .onAppear(perform: schedulePasteboardDetection)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            schedulePasteboardDetection()
        }
        .environment(authState)
        .environment(ToastManager.shared)

    }
    
    /// The banners that show notifications and toast messages.
    var banners: some View {
        VStack(spacing: 0) {
            if showPasteboardBanner {
                PasteboardImportBanner(
                    onImport: handlePasteboardImport,
                    onDismiss: {
                        showPasteboardBanner = false
                    }
                )
                .transition(.move(edge: .bottom))
            }
            
            if ToastManager.shared.isShowingToast, let toast = ToastManager.shared.currentToast {
                toast
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
}

extension ContentView {
    
    /// Asynchronously checks the pasteboard for a web URL and shows the import banner if found.
    private func schedulePasteboardDetection() {
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        Task {
            let result = await PasteboardLinkDetector.detectProbableWebURL(previousChangeCount: lastPasteboardChangeCount)
            await MainActor.run {
                lastPasteboardChangeCount = result.changeCount
                showPasteboardBanner = result.shouldShowBanner
            }
        }
    }
    
    /// Only read the actual pasteboard contents when the user explicitly taps Import.
    private func handlePasteboardImport() {
        defer { showPasteboardBanner = false }
        
        guard let string = UIPasteboard.general.string,
              let url = URL(string: string),
              url.scheme?.hasPrefix("http") == true else {
            ToastManager.shared.showError("Clipboard does not contain a valid recipe URL.")
            return
        }
        
        // TODO: Route the detected URL into the correct import flow.
        AppLogger.info(.ui, "Importing recipe from clipboard URL: \(url)")
    }
}
