import SwiftUI

private enum CustomKeyboardGuidePalette {
    static let backgroundTop = Color(red: 0.99, green: 0.97, blue: 0.92)
    static let backgroundBottom = Color(red: 0.93, green: 0.95, blue: 0.98)
    static let ink = Color(red: 0.11, green: 0.13, blue: 0.18)
    static let secondaryInk = Color(red: 0.31, green: 0.36, blue: 0.43)
    static let accent = Color(red: 0.92, green: 0.43, blue: 0.24)
    static let accentPressed = Color(red: 0.82, green: 0.35, blue: 0.18)
    static let accentTint = Color(red: 0.99, green: 0.92, blue: 0.88)
    static let line = Color.white.opacity(0.82)
    static let cardShadow = Color.black.opacity(0.12)
}

struct CustomKeyboardGuideCard: View {
    let onEnable: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("どちらのキーボードを使いますか？")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(CustomKeyboardGuidePalette.ink)
                .padding(.top, 10)

            HStack(spacing: 16) {
                keyboardOption(
                    title: "標準キーボード",
                    imageName: "IosKeyboard",
                    pros: ["いつもと同じ使いやすさ"],
                    cons: ["予測変換に履歴が残る"],
                    action: onDismiss
                )

                keyboardOption(
                    title: "独自キーボード",
                    imageName: "NoPeekKeyboard",
                    pros: ["予測変換が記録されない"],
                    cons: ["たまに不具合がある", "漢字に変換できない"],
                    action: onEnable
                )
            }
            .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(CustomKeyboardGuidePalette.accent)

                Text("設定からいつでも変更できます")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(CustomKeyboardGuidePalette.secondaryInk)
            }
        }
        .padding(24)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: CustomKeyboardGuidePalette.cardShadow, radius: 26, y: 14)
    }

    private func keyboardOption(title: String, imageName: String, pros: [String], cons: [String], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Spacer(minLength: 0)
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(CustomKeyboardGuidePalette.line, lineWidth: 1)
                        )
                    Spacer(minLength: 0)
                }

                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(CustomKeyboardGuidePalette.ink)
                    .frame(maxWidth: .infinity, alignment: .center)

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(pros, id: \.self) { pro in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 12, weight: .bold))
                                .padding(.top, 1)
                            Text(pro)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(CustomKeyboardGuidePalette.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    ForEach(cons, id: \.self) { con in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 12, weight: .bold))
                                .padding(.top, 1)
                            Text(con)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(CustomKeyboardGuidePalette.secondaryInk)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.white.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(CustomKeyboardGuidePalette.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        CustomKeyboardGuidePalette.backgroundTop,
                        CustomKeyboardGuidePalette.backgroundBottom
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(CustomKeyboardGuidePalette.line, lineWidth: 1)
            )
    }
}

private struct GuidePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        configuration.isPressed
                            ? CustomKeyboardGuidePalette.accentPressed
                            : CustomKeyboardGuidePalette.accent
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    CustomKeyboardGuideCard(
        onEnable: {},
        onDismiss: {}
    )
    .padding()
    .background(Color.black.opacity(0.08))
}
