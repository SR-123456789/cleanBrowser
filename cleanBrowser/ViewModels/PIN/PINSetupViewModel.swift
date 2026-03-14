import SwiftUI

@MainActor
final class PINSetupViewModel: ObservableObject {
    enum Mode {
        case initial
        case change
    }

    enum Step {
        case currentPIN
        case newPIN
        case confirmPIN
    }

    let mode: Mode
    private let pinService: any PINManaging

    @Published var currentStep: Step
    @Published var currentPIN = ""
    @Published var newPIN = ""
    @Published var confirmPIN = ""
    @Published var errorMessage: String?
    @Published var isCompleted = false

    init(mode: Mode, pinService: any PINManaging) {
        self.mode = mode
        self.pinService = pinService
        self.currentStep = mode == .initial ? .newPIN : .currentPIN
    }

    var currentTitle: String {
        switch currentStep {
        case .currentPIN: return "現在のPINを入力してください"
        case .newPIN: return mode == .initial ? "PIN設定" : "新しいPINを入力してください"
        case .confirmPIN: return "もう一度入力"
        }
    }

    var currentDigitCount: Int {
        currentInput.count
    }

    private var currentInput: String {
        switch currentStep {
        case .currentPIN:
            return currentPIN
        case .newPIN:
            return newPIN
        case .confirmPIN:
            return confirmPIN
        }
    }

    func appendDigit(_ digit: String) {
        guard currentInput.count < 4 else { return }

        switch currentStep {
        case .currentPIN:
            currentPIN.append(digit)
            if currentPIN.count == 4 {
                onPINEntered(currentPIN)
            }
        case .newPIN:
            newPIN.append(digit)
            if newPIN.count == 4 {
                onPINEntered(newPIN)
            }
        case .confirmPIN:
            confirmPIN.append(digit)
            if confirmPIN.count == 4 {
                onPINEntered(confirmPIN)
            }
        }
    }

    func deleteLastDigit() {
        switch currentStep {
        case .currentPIN:
            guard !currentPIN.isEmpty else { return }
            currentPIN.removeLast()
        case .newPIN:
            guard !newPIN.isEmpty else { return }
            newPIN.removeLast()
        case .confirmPIN:
            guard !confirmPIN.isEmpty else { return }
            confirmPIN.removeLast()
        }
    }

    func onPINEntered(_ pin: String) {
        switch currentStep {
        case .currentPIN:
            if pinService.verifyPIN(pin) {
                currentStep = .newPIN
                errorMessage = nil
            } else {
                errorMessage = "PINが間違えています"
                currentPIN = ""
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    self?.errorMessage = nil
                }
            }

        case .newPIN:
            errorMessage = nil
            currentStep = .confirmPIN

        case .confirmPIN:
            if pin == newPIN {
                pinService.updatePIN(pin)
                isCompleted = true
            } else {
                errorMessage = "PINが一致しません"
                confirmPIN = ""
                newPIN = ""
                currentStep = .newPIN
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    self?.errorMessage = nil
                }
            }
        }
    }
}
