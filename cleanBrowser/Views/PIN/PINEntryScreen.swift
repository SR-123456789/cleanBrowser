import SwiftUI

struct PINEntryScreen: View {
    @ObservedObject var viewModel: ContentViewModel

    var body: some View {
        PINPadView(
            title: "PINを入力してください",
            enteredDigits: viewModel.pinInput.count,
            errorMessage: viewModel.errorMessage,
            style: .regular,
            onDigitTapped: viewModel.appendDigit,
            onDeleteTapped: viewModel.deleteLastDigit
        )
        .background(Color.black)
        .foregroundColor(.white)
    }
}
