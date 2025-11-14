import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @State private var showPasteboardBanner = false
    @State private var lastPasteboardChangeCount: Int = -1
    
    // Services
    var mealieAPIService: MealieAPIServiceProtocol
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
        print("Importing recipe from clipboard URL: \(url)")
    }
}
