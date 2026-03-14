import SwiftUI

struct DailyInterstitialGateOverlay: View {
    let title: String
    let description: String
    let detail: String
    let buttonTitle: String
    let isButtonEnabled: Bool
    let isLoading: Bool
    let onPrimaryAction: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(Color.blue)

                VStack(spacing: 10) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)

                    Text(description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: onPrimaryAction) {
                    HStack(spacing: 10) {
                        if isLoading && !isButtonEnabled {
                            ProgressView()
                                .tint(.white)
                        }

                        Text(buttonTitle)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(isButtonEnabled ? Color.blue : Color.blue.opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .disabled(!isButtonEnabled)
            }
            .padding(28)
            .frame(maxWidth: 420)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 20, y: 8)
            .padding(24)
        }
    }
}

#Preview {
    DailyInterstitialGateOverlay(
        title: "1日1回の広告表示",
        description: "無料で使い続けられるよう、1日1回だけ広告の表示をお願いしています。広告の表示が終わると、その日は再表示されません。",
        detail: "この案内は1日1回だけ表示されます。",
        buttonTitle: "広告を表示する",
        isButtonEnabled: true,
        isLoading: false,
        onPrimaryAction: {}
    )
}
