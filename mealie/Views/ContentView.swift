import SwiftUI
import SwiftData

struct ContentView: View {
    
    @State private var authState = AuthenticationState()
    @State private var showPasteboardBanner = false
    @State private var pasteboardURL: URL?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if authState.isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
            
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
                        .padding(.bottom, authState.isLoggedIn ? 83 : 0)
                }
            }
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
} 
