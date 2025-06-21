import SwiftUI
import Observation

@Observable
final class ToastManager {
    static let shared = ToastManager()
    
    var currentToast: ToastMessage?
    var isShowingToast = false
    
    private var toastQueue: [ToastMessage] = []
    private var isProcessingQueue = false
    
    private init() {} // Private initializer for singleton
    
    func showToast(_ message: String, type: ToastMessage.ToastType = .error) {
        let toast = ToastMessage(
            message: message,
            type: type,
            onDismiss: { [weak self] in
                self?.hideToast()
            },
            queueCount: toastQueue.count
        )
        
        // Add to queue
        toastQueue.append(toast)
        
        // Process queue if not already processing
        if !isProcessingQueue {
            processNextToast()
        }
    }
    
    private func processNextToast() {
        guard !toastQueue.isEmpty && !isShowingToast else { return }
        
        isProcessingQueue = true
        currentToast = toastQueue.removeFirst()
        isShowingToast = true
        
        // Auto-dismiss after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            if self?.isShowingToast == true {
                self?.hideToast()
            }
        }
    }
    
    func hideToast() {
        isShowingToast = false
        currentToast = nil
        
        // Process next toast in queue
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.isProcessingQueue = false
            self?.processNextToast()
        }
    }
    
    func showError(_ message: String) {
        showToast(message, type: .error)
    }
    
    func showWarning(_ message: String) {
        showToast(message, type: .warning)
    }
    
    func showSuccess(_ message: String) {
        showToast(message, type: .success)
    }
    
    func showInfo(_ message: String) {
        showToast(message, type: .info)
    }
    
    // Clear all pending toasts
    func clearQueue() {
        toastQueue.removeAll()
        if isShowingToast {
            hideToast()
        }
    }
    
    // Get queue status for debugging
    var queueCount: Int {
        return toastQueue.count
    }
} 