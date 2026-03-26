import SwiftUI

private enum StartupUpdateOverlayPalette {
    static let backgroundTop = Color(red: 0.98, green: 0.96, blue: 0.92)
    static let backgroundBottom = Color(red: 0.93, green: 0.95, blue: 0.99)
    static let accent = Color(red: 0.88, green: 0.33, blue: 0.17)
    static let accentPressed = Color(red: 0.78, green: 0.27, blue: 0.13)
    static let secondaryFill = Color.white.opacity(0.84)
    static let ink = Color(red: 0.10, green: 0.13, blue: 0.18)
    static let secondaryInk = Color(red: 0.34, green: 0.39, blue: 0.47)
    static let line = Color.white.opacity(0.86)
    static let cardShadow = Color.black.opacity(0.16)
}

struct StartupUpdateOverlay: View {
    let prompt: StartupUpdatePrompt
    let onPrimaryAction: () -> Void
    let onDismiss: (() -> Void)?

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    Image(systemName: prompt.isMandatory ? "arrow.down.app.fill" : "arrow.down.app")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(StartupUpdateOverlayPalette.accent)

                    Spacer(minLength: 0)

                    Text(prompt.isMandatory ? "必須" : "おすすめ")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(StartupUpdateOverlayPalette.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(StartupUpdateOverlayPalette.secondaryFill)
                        .clipShape(Capsule())
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(prompt.title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(StartupUpdateOverlayPalette.ink)

                    Text(prompt.message)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(StartupUpdateOverlayPalette.secondaryInk)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 10) {
                    Button(action: onPrimaryAction) {
                        Text("アップデートする")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                    }
                    .buttonStyle(StartupUpdatePrimaryButtonStyle())

                    if let onDismiss {
                        Button(action: onDismiss) {
                            Text("あとで")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(StartupUpdateOverlayPalette.ink)
                        .background(StartupUpdateOverlayPalette.secondaryFill)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(StartupUpdateOverlayPalette.line, lineWidth: 1)
                        )
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: 420)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .shadow(color: StartupUpdateOverlayPalette.cardShadow, radius: 26, y: 16)
            .padding(24)
        }
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        StartupUpdateOverlayPalette.backgroundTop,
                        StartupUpdateOverlayPalette.backgroundBottom
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(StartupUpdateOverlayPalette.line, lineWidth: 1)
            )
    }
}

private struct StartupUpdatePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        configuration.isPressed
                            ? StartupUpdateOverlayPalette.accentPressed
                            : StartupUpdateOverlayPalette.accent
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    StartupUpdateOverlay(
        prompt: StartupUpdatePrompt(
            title: "アップデートしてください",
            message: "現在のバージョンはサポート対象外です。App Store から最新版に更新してください。",
            updateURL: URL(string: "https://apps.apple.com/app/id1234567890"),
            isMandatory: true
        ),
        onPrimaryAction: {},
        onDismiss: nil
    )
}
