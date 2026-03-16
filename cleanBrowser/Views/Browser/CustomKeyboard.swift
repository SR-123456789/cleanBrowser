import SwiftUI
import WebKit

enum CustomKeyboardPalette {
    static let board = Color(red: 0.82, green: 0.88, blue: 0.93)
    static let boardStroke = Color.white.opacity(0.75)
    static let utilityKey = Color(red: 0.72, green: 0.80, blue: 0.87)
    static let utilityPressed = Color(red: 0.58, green: 0.69, blue: 0.79)
    static let primaryKey = Color(red: 0.97, green: 0.98, blue: 0.99)
    static let primaryPressed = Color(red: 0.89, green: 0.93, blue: 0.97)
    static let accentKey = Color(red: 0.94, green: 0.50, blue: 0.34)
    static let accentPressed = Color(red: 0.84, green: 0.42, blue: 0.26)
    static let badge = Color(red: 0.24, green: 0.31, blue: 0.40)
    static let badgeSecondary = Color(red: 0.46, green: 0.57, blue: 0.68)
    static let label = Color(red: 0.07, green: 0.10, blue: 0.15)
    static let inverseLabel = Color.white
}

enum CustomKeyboardMetrics {
    static let panelCornerRadius: CGFloat = 16
    static let keyCornerRadius: CGFloat = 13
    static let keyUnitHeight: CGFloat = 54
    static let secondaryKeyHeight: CGFloat = 48
    static let sidebarWidth: CGFloat = 54
    static let contentSpacing: CGFloat = 6
    static let panelPadding: CGFloat = 6
    static let inlineUtilityKeyWidth: CGFloat = 52
    static let bottomUtilityKeyWidth: CGFloat = 58
    static let narrowBottomKeyWidth: CGFloat = 50
    static let returnKeyWidth: CGFloat = 86
    static let secondRowInset: CGFloat = 18
}

struct CustomKeyboard: View {
    let webView: WKWebView?
    @StateObject private var viewModel = CustomKeyboardViewModel()
    @Binding var isKeyboardVisible: Bool
    let onDismiss: () -> Void
    let onSwitchToSystemKeyboard: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            keyboardHeader
            keyboardContent
        }
        .padding(.horizontal, 3)
        .padding(.top, 3)
        .padding(.bottom, 6)
        .onAppear {
            viewModel.webView = webView
        }
        .onChange(of: webView) { _, newValue in
            viewModel.webView = newValue
        }
    }

    private var keyboardHeader: some View {
        HStack(spacing: 8) {
            Button(action: onSwitchToSystemKeyboard) {
                Label("標準キーボード", systemImage: "keyboard")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(CustomKeyboardPalette.inverseLabel.opacity(0.92))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(CustomKeyboardPalette.badge)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Label("閉じる", systemImage: "keyboard.chevron.compact.down")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(CustomKeyboardPalette.inverseLabel.opacity(0.92))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(CustomKeyboardPalette.badgeSecondary)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var keyboardContent: some View {
        switch viewModel.currentLayout {
        case .hiragana, .katakana:
            japaneseKeyboardBody
        case .english:
            standardPanel {
                englishPanel
            }
        case .numbers:
            standardPanel {
                numbersPanel
            }
        }
    }

    private var japaneseKeyboardBody: some View {
        HStack(alignment: .top, spacing: CustomKeyboardMetrics.contentSpacing) {
            sidebarColumn(viewModel.leadingSidebarKeys)
            standardPanel {
                japanesePanel
            }
            sidebarColumn(viewModel.trailingSidebarKeys)
        }
    }

    private var japanesePanel: some View {
        VStack(spacing: CustomKeyboardMetrics.contentSpacing) {
            ForEach(Array(viewModel.activeJapaneseRows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: CustomKeyboardMetrics.contentSpacing) {
                    ForEach(row, id: \.self) { character in
                        JapaneseFlickKey(
                            character: character,
                            flickOptions: viewModel.flickOptions(for: character)
                        ) { direction in
                            viewModel.handleJapaneseInput(character, flickDirection: direction)
                        }
                    }
                }
            }
        }
    }

    private var englishPanel: some View {
        VStack(spacing: CustomKeyboardMetrics.contentSpacing) {
            characterRow(viewModel.englishRows[0]) { character in
                viewModel.handleEnglishInput(character)
            }
            characterRow(
                viewModel.englishRows[1],
                sideInset: CustomKeyboardMetrics.secondRowInset
            ) { character in
                viewModel.handleEnglishInput(character)
            }
            inlineCharacterRow(
                characters: viewModel.englishRows[2],
                leadingKey: viewModel.englishLeadingInlineKey,
                trailingKey: viewModel.englishTrailingInlineKey
            ) { character in
                viewModel.handleEnglishInput(character)
            }
            bottomRow(viewModel.englishBottomRowKeys)
        }
    }

    private var numbersPanel: some View {
        VStack(spacing: CustomKeyboardMetrics.contentSpacing) {
            characterRow(viewModel.numbersRows[0]) { character in
                viewModel.insertText(character)
            }
            characterRow(viewModel.numbersRows[1]) { character in
                viewModel.insertText(character)
            }
            inlineCharacterRow(
                characters: viewModel.numbersRows[2],
                leadingKey: viewModel.numbersLeadingInlineKey,
                trailingKey: viewModel.numbersTrailingInlineKey
            ) { character in
                viewModel.insertText(character)
            }
            bottomRow(viewModel.numbersBottomRowKeys)
        }
    }

    private func standardPanel<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .frame(maxWidth: .infinity)
            .padding(CustomKeyboardMetrics.panelPadding)
            .background(
                RoundedRectangle(cornerRadius: CustomKeyboardMetrics.panelCornerRadius, style: .continuous)
                    .fill(CustomKeyboardPalette.board)
                    .overlay(
                        RoundedRectangle(cornerRadius: CustomKeyboardMetrics.panelCornerRadius, style: .continuous)
                            .stroke(CustomKeyboardPalette.boardStroke, lineWidth: 0.8)
                    )
            )
    }

    private func characterRow(
        _ characters: [String],
        sideInset: CGFloat = 0,
        onTap: @escaping (String) -> Void
    ) -> some View {
        HStack(spacing: CustomKeyboardMetrics.contentSpacing) {
            if sideInset > 0 {
                Color.clear
                    .frame(width: sideInset, height: 0)
            }

            ForEach(characters, id: \.self) { character in
                CharacterKeyButton(label: displayLabel(for: character)) {
                    onTap(character)
                }
            }

            if sideInset > 0 {
                Color.clear
                    .frame(width: sideInset, height: 0)
            }
        }
    }

    private func inlineCharacterRow(
        characters: [String],
        leadingKey: CustomKeyboardViewModel.InlineKeyModel,
        trailingKey: CustomKeyboardViewModel.InlineKeyModel,
        onTap: @escaping (String) -> Void
    ) -> some View {
        HStack(spacing: CustomKeyboardMetrics.contentSpacing) {
            InlineActionKeyButton(model: leadingKey) {
                performSidebarAction(leadingKey.action)
            }
            .frame(width: CustomKeyboardMetrics.inlineUtilityKeyWidth)

            ForEach(characters, id: \.self) { character in
                CharacterKeyButton(label: displayLabel(for: character)) {
                    onTap(character)
                }
            }

            InlineActionKeyButton(model: trailingKey) {
                performSidebarAction(trailingKey.action)
            }
            .frame(width: CustomKeyboardMetrics.inlineUtilityKeyWidth)
        }
    }

    private func bottomRow(
        _ keys: [CustomKeyboardViewModel.InlineKeyModel]
    ) -> some View {
        HStack(spacing: CustomKeyboardMetrics.contentSpacing) {
            ForEach(keys) { key in
                InlineActionKeyButton(model: key) {
                    performSidebarAction(key.action)
                }
                .frame(
                    maxWidth: bottomRowUsesFlexibleWidth(for: key) ? .infinity : nil,
                    minHeight: CustomKeyboardMetrics.secondaryKeyHeight
                )
                .frame(width: bottomRowFixedWidth(for: key))
            }
        }
    }

    private func sidebarColumn(_ keys: [CustomKeyboardViewModel.SidebarKeyModel]) -> some View {
        VStack(spacing: CustomKeyboardMetrics.contentSpacing) {
            ForEach(keys) { key in
                SidebarKeyButton(
                    model: key,
                    rowHeight: CustomKeyboardMetrics.keyUnitHeight
                ) {
                    performSidebarAction(key.action)
                }
            }
        }
        .frame(width: CustomKeyboardMetrics.sidebarWidth)
    }

    private func performSidebarAction(_ action: CustomKeyboardViewModel.SidebarAction) {
        let shouldDismiss = viewModel.handleSidebarAction(action)
        guard shouldDismiss else { return }

        isKeyboardVisible = false
    }

    private func displayLabel(for character: String) -> String {
        guard viewModel.currentLayout == .english else {
            return character
        }

        return viewModel.isShiftPressed ? character : character.lowercased()
    }

    private func bottomRowUsesFlexibleWidth(
        for key: CustomKeyboardViewModel.InlineKeyModel
    ) -> Bool {
        if case .insertSpace = key.action {
            return true
        }

        return false
    }

    private func bottomRowFixedWidth(
        for key: CustomKeyboardViewModel.InlineKeyModel
    ) -> CGFloat? {
        switch key.action {
        case .insertSpace:
            return nil
        case .insertNewline:
            return CustomKeyboardMetrics.returnKeyWidth
        case .insertText:
            return CustomKeyboardMetrics.narrowBottomKeyWidth
        case .dismissKeyboard, .toggleShift, .deleteBackward:
            return CustomKeyboardMetrics.inlineUtilityKeyWidth
        case .selectLayout:
            return CustomKeyboardMetrics.bottomUtilityKeyWidth
        }
    }
}

private struct SidebarKeyButton: View {
    let model: CustomKeyboardViewModel.SidebarKeyModel
    let rowHeight: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let systemImageName = model.systemImageName {
                    Image(systemName: systemImageName)
                        .font(.system(size: 20, weight: .semibold))
                } else {
                    Text(model.title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)
                }
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity, minHeight: height)
        }
        .buttonStyle(
            KeyboardSurfaceButtonStyle(
                fillColor: fillColor,
                pressedFillColor: pressedFillColor,
                strokeColor: Color.white.opacity(0.42)
            )
        )
    }

    private var height: CGFloat {
        rowHeight * CGFloat(model.heightUnits) + CustomKeyboardMetrics.contentSpacing * CGFloat(model.heightUnits - 1)
    }

    private var fillColor: Color {
        switch model.style {
        case .utility:
            return CustomKeyboardPalette.utilityKey
        case .selected:
            return CustomKeyboardPalette.accentKey
        case .accent:
            return CustomKeyboardPalette.accentKey
        }
    }

    private var pressedFillColor: Color {
        switch model.style {
        case .utility:
            return CustomKeyboardPalette.utilityPressed
        case .selected, .accent:
            return CustomKeyboardPalette.accentPressed
        }
    }

    private var foregroundColor: Color {
        switch model.style {
        case .utility:
            return CustomKeyboardPalette.label
        case .selected, .accent:
            return CustomKeyboardPalette.inverseLabel
        }
    }
}

private struct CharacterKeyButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 19, weight: .medium, design: .rounded))
                .foregroundColor(CustomKeyboardPalette.label)
                .frame(maxWidth: .infinity, minHeight: CustomKeyboardMetrics.secondaryKeyHeight)
        }
        .buttonStyle(
            KeyboardSurfaceButtonStyle(
                fillColor: CustomKeyboardPalette.primaryKey,
                pressedFillColor: CustomKeyboardPalette.primaryPressed,
                strokeColor: Color.black.opacity(0.06)
            )
        )
    }
}

private struct InlineActionKeyButton: View {
    let model: CustomKeyboardViewModel.InlineKeyModel
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let systemImageName = model.systemImageName {
                    Image(systemName: systemImageName)
                        .font(.system(size: 19, weight: .semibold))
                } else {
                    Text(model.title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity, minHeight: CustomKeyboardMetrics.secondaryKeyHeight)
        }
        .buttonStyle(
            KeyboardSurfaceButtonStyle(
                fillColor: fillColor,
                pressedFillColor: pressedFillColor,
                strokeColor: Color.white.opacity(0.42)
            )
        )
    }

    private var fillColor: Color {
        switch model.style {
        case .utility:
            return CustomKeyboardPalette.utilityKey
        case .selected, .accent:
            return CustomKeyboardPalette.accentKey
        }
    }

    private var pressedFillColor: Color {
        switch model.style {
        case .utility:
            return CustomKeyboardPalette.utilityPressed
        case .selected, .accent:
            return CustomKeyboardPalette.accentPressed
        }
    }

    private var foregroundColor: Color {
        switch model.style {
        case .utility:
            return CustomKeyboardPalette.label
        case .selected, .accent:
            return CustomKeyboardPalette.inverseLabel
        }
    }
}

private struct KeyboardSurfaceButtonStyle: ButtonStyle {
    let fillColor: Color
    let pressedFillColor: Color
    let strokeColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: CustomKeyboardMetrics.keyCornerRadius, style: .continuous)
                    .fill(configuration.isPressed ? pressedFillColor : fillColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CustomKeyboardMetrics.keyCornerRadius, style: .continuous)
                    .stroke(strokeColor, lineWidth: 0.8)
            )
    }
}
