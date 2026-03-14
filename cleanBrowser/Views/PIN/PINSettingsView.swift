import SwiftUI

struct PINSettingsView: View {
    @StateObject private var viewModel: PINSetupViewModel
    @Environment(\.dismiss) private var dismiss

    init(pinService: any PINManaging) {
        _viewModel = StateObject(wrappedValue: PINSetupViewModel(mode: .change, pinService: pinService))
    }

    var body: some View {
        NavigationView {
            PINPadView(
                title: viewModel.currentTitle,
                message: viewModel.currentMessage,
                enteredDigits: viewModel.currentDigitCount,
                errorMessage: viewModel.errorMessage,
                style: .regular,
                onDigitTapped: viewModel.appendDigit,
                onDeleteTapped: viewModel.deleteLastDigit
            )
            .background(Color.black)
            .navigationTitle("PIN再設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onChange(of: viewModel.isCompleted) { _, completed in
                if completed {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    PINSettingsView(pinService: UserDefaultsPINService())
}
