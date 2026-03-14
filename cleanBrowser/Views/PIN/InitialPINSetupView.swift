import SwiftUI

struct InitialPINSetupView: View {
    @StateObject private var viewModel: PINSetupViewModel
    let onPINSet: () -> Void

    init(pinService: any PINManaging, onPINSet: @escaping () -> Void) {
        self.onPINSet = onPINSet
        _viewModel = StateObject(wrappedValue: PINSetupViewModel(mode: .initial, pinService: pinService))
    }

    var body: some View {
        VStack {
            PINPadView(
                title: viewModel.currentTitle,
                enteredDigits: viewModel.currentDigitCount,
                errorMessage: viewModel.errorMessage,
                style: .compact,
                onDigitTapped: viewModel.appendDigit,
                onDeleteTapped: viewModel.deleteLastDigit
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .ignoresSafeArea()
        .onChange(of: viewModel.isCompleted) { _, completed in
            if completed {
                onPINSet()
            }
        }
    }
}

#Preview {
    InitialPINSetupView(pinService: UserDefaultsPINService(), onPINSet: {})
}
