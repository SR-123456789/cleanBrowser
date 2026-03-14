import SwiftUI

@MainActor
final class ContentViewModel: ObservableObject {
    @Published var isUnlocked = false
    @Published var pinInput = ""
    @Published var errorMessage: String?
    @Published var showPINSettings = false
    @Published var hasPINBeenSet = false
    @Published var isPrivacyShieldVisible = false

    private let pinService: any PINManaging
    private var shouldLockOnNextActive = false
    private var pendingInactiveShieldWorkItem: DispatchWorkItem?
    private let inactiveShieldDelay: TimeInterval = 0.35

    init(pinService: any PINManaging) {
        self.pinService = pinService
    }

    var shouldShowInitialSetup: Bool {
        (pinService.isFirstLaunch || !pinService.hasPINSet) && !hasPINBeenSet
    }

    func verifyPIN(_ pin: String) {
        if pinService.verifyPIN(pin) {
            withAnimation {
                isUnlocked = true
            }
            errorMessage = nil
        } else {
            errorMessage = "PINが間違えています"
            pinInput = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.errorMessage = nil
            }
        }
    }

    func resetToPIN() {
        isUnlocked = false
        pinInput = ""
        errorMessage = nil
    }

    func onPINSet() {
        hasPINBeenSet = true
    }

    func appendDigit(_ digit: String) {
        guard pinInput.count < 4 else { return }
        pinInput.append(digit)
        if pinInput.count == 4 {
            verifyPIN(pinInput)
        }
    }

    func deleteLastDigit() {
        guard !pinInput.isEmpty else { return }
        pinInput.removeLast()
    }

    func handleScenePhase(_ scenePhase: ScenePhase) {
        switch scenePhase {
        case .active:
            cancelPendingInactiveShield()
            isPrivacyShieldVisible = false
            if shouldLockOnNextActive && pinService.hasPINSet {
                resetToPIN()
            }
            shouldLockOnNextActive = false
        case .background:
            cancelPendingInactiveShield()
            isPrivacyShieldVisible = true
            shouldLockOnNextActive = true
        case .inactive:
            scheduleInactiveShield()
        @unknown default:
            break
        }
    }

    private func scheduleInactiveShield() {
        cancelPendingInactiveShield()

        let workItem = DispatchWorkItem { [weak self] in
            self?.isPrivacyShieldVisible = true
        }

        pendingInactiveShieldWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + inactiveShieldDelay, execute: workItem)
    }

    private func cancelPendingInactiveShield() {
        pendingInactiveShieldWorkItem?.cancel()
        pendingInactiveShieldWorkItem = nil
    }
}
