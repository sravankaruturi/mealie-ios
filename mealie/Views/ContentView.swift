import SwiftUI
import SwiftData

struct ContentView: View {
    
    
    @State private var showPasteboardBanner = false
    @State private var pasteboardURL: URL?
    
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
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            if let string = UIPasteboard.general.string, let url = URL(string: string), url.scheme?.hasPrefix("http") == true {
                pasteboardURL = url
                showPasteboardBanner = true
            }
        }
        .environment(authState)
        .environment(ToastManager.shared)

    }
    
    /// The banners that show notifications and toast messages.
    var banners: some View {
        VStack(spacing: 0) {
            if showPasteboardBanner, let url = pasteboardURL {
                PasteboardImportBanner(url: url, onImport: {
                    // Handle import
                    showPasteboardBanner = false
                }, onDismiss: {
                    showPasteboardBanner = false
                })
                .transition(.move(edge: .bottom))
            }
            
            if ToastManager.shared.isShowingToast, let toast = ToastManager.shared.currentToast {
                toast
                    .transition(.move(edge: .bottom).combined(with: .opacity))
//                    .padding(.bottom, authState.isLoggedIn ? 83 : 0)
            }
        }
    }
    
}
