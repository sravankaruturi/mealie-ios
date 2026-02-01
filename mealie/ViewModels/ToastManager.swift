import SwiftUI
import Observation

@Observable
/// Singleton that manages a queue of toast notifications displayed to the user.
final class ToastManager {
    /// Shared singleton instance.
    static let shared = ToastManager()

    /// The toast currently being displayed, if any.
    var currentToast: ToastMessage?
    /// Whether a toast is currently visible.
    var isShowingToast = false
    
    private var toastQueue: [ToastMessage] = []
    private var isProcessingQueue = false
    
    private init() {} // Private initializer for singleton
    
    /// Enqueues a toast message with the given type.
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
    
    /// Displays the next queued toast, if any.
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
    
    /// Dismisses the current toast and shows the next one in the queue.
    func hideToast() {
        isShowingToast = false
        currentToast = nil
        
        // Process next toast in queue
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.isProcessingQueue = false
            self?.processNextToast()
        }
    }
    
    /// Convenience: shows an error toast.
    func showError(_ message: String) {
        showToast(message, type: .error)
    }
    
    /// Convenience: shows a warning toast.
    func showWarning(_ message: String) {
        showToast(message, type: .warning)
    }
    
    /// Convenience: shows a success toast.
    func showSuccess(_ message: String) {
        showToast(message, type: .success)
    }
    
    /// Convenience: shows an informational toast.
    func showInfo(_ message: String) {
        showToast(message, type: .info)
    }
    
    /// Removes all pending toasts from the queue.
    func clearQueue() {
        toastQueue.removeAll()
        if isShowingToast {
            hideToast()
        }
    }
    
    /// The number of toasts waiting in the queue.
    var queueCount: Int {
        return toastQueue.count
    }
} 