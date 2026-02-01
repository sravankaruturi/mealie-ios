import Foundation
import Testing
@testable import mealIO

@MainActor
@Suite(.serialized)
struct ToastManagerTests {

    private func cleanSlate() {
        ToastManager.shared.clearQueue()
    }

    // MARK: - showToast Tests

    @Test
    func showToast_displaysToast() {
        cleanSlate()
        ToastManager.shared.showToast("Test message", type: .error)
        #expect(ToastManager.shared.isShowingToast == true)
        #expect(ToastManager.shared.currentToast != nil)
        cleanSlate()
    }

    @Test
    func showError_setsErrorType() {
        cleanSlate()
        ToastManager.shared.showError("Error")
        #expect(ToastManager.shared.currentToast?.type == .error)
        cleanSlate()
    }

    @Test
    func showSuccess_setsSuccessType() {
        cleanSlate()
        ToastManager.shared.showSuccess("Success")
        #expect(ToastManager.shared.currentToast?.type == .success)
        cleanSlate()
    }

    @Test
    func showWarning_setsWarningType() {
        cleanSlate()
        ToastManager.shared.showWarning("Warning")
        #expect(ToastManager.shared.currentToast?.type == .warning)
        cleanSlate()
    }

    @Test
    func showInfo_setsInfoType() {
        cleanSlate()
        ToastManager.shared.showInfo("Info")
        #expect(ToastManager.shared.currentToast?.type == .info)
        cleanSlate()
    }

    // MARK: - hideToast Tests

    @Test
    func hideToast_dismissesCurrent() {
        cleanSlate()
        ToastManager.shared.showToast("Test", type: .info)
        ToastManager.shared.hideToast()
        #expect(ToastManager.shared.isShowingToast == false)
        #expect(ToastManager.shared.currentToast == nil)
        cleanSlate()
    }

    // MARK: - Queue Tests

    @Test
    func clearQueue_emptiesEverything() {
        cleanSlate()
        ToastManager.shared.showToast("1", type: .info)
        ToastManager.shared.showToast("2", type: .info)
        ToastManager.shared.showToast("3", type: .info)
        ToastManager.shared.clearQueue()
        #expect(ToastManager.shared.queueCount == 0)
        #expect(ToastManager.shared.isShowingToast == false)
    }

    @Test
    func queueCount_reflectsPendingCount() {
        cleanSlate()
        // First toast shows immediately, rest queue
        ToastManager.shared.showToast("1", type: .info)
        ToastManager.shared.showToast("2", type: .info)
        ToastManager.shared.showToast("3", type: .info)
        // 1 is showing, 2 and 3 are in queue
        #expect(ToastManager.shared.queueCount == 2)
        cleanSlate()
    }
}
