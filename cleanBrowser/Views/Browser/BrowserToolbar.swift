import SwiftUI

struct BrowserToolbar: View {
    let currentURL: String
    let canGoBack: Bool
    let canGoForward: Bool
    let isLoading: Bool
    let isMutedGlobal: Bool
    let tabCount: Int
    let onGoBack: () -> Void
    let onGoForward: () -> Void
    let onSubmitAddress: (String) -> Void
    let onToggleMute: () -> Void
    let onShowSettings: () -> Void
    let onShowTabs: () -> Void

    @State private var addressText = ""
    @State private var isEditingAddress = false

    private enum UI {
        static let buttonSize: CGFloat = 36
        static let iconSize: CGFloat = 16
        static let hSpacing: CGFloat = 12
        static let toolbarHPadding: CGFloat = 12
        static let toolbarVPadding: CGFloat = 8
        static let addressCorner: CGFloat = 12
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: UI.hSpacing) {
                HStack(spacing: UI.hSpacing) {
                    Button(action: onGoBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: UI.iconSize, weight: .medium))
                            .foregroundColor(canGoBack ? .primary : .secondary)
                            .frame(width: UI.buttonSize, height: UI.buttonSize)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Circle())
                    }
                    .disabled(!canGoBack)
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")

                    Button(action: onGoForward) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: UI.iconSize, weight: .medium))
                            .foregroundColor(canGoForward ? .primary : .secondary)
                            .frame(width: UI.buttonSize, height: UI.buttonSize)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Circle())
                    }
                    .disabled(!canGoForward)
                    .buttonStyle(.plain)
                    .accessibilityLabel("Forward")
                }

                HStack(spacing: 8) {
                    Image(systemName: currentURL.hasPrefix("https://") ? "lock.fill" : "lock.open")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(currentURL.hasPrefix("https://") ? .green : .orange)

                    if isEditingAddress {
                        URLTextField(text: $addressText, isFirstResponder: $isEditingAddress, placeholder: "Enter URL or search", onCommit: { submittedText in
                            onSubmitAddress(submittedText)
                            isEditingAddress = false
                        })
                        .onAppear { addressText = currentURL }
                    } else {
                        HStack {
                            Text(BrowserURLResolver.displayText(for: currentURL))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { isEditingAddress = true }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(UI.addressCorner)

                HStack(spacing: UI.hSpacing) {
                    Button(action: onToggleMute) {
                        Image(systemName: isMutedGlobal ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: UI.iconSize, weight: .medium))
                            .foregroundColor(isMutedGlobal ? .red : .primary)
                            .frame(width: UI.buttonSize, height: UI.buttonSize)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isMutedGlobal ? "Unmute" : "Mute")

                    Button(action: onShowSettings) {
                        Image(systemName: "gearshape")
                            .font(.system(size: UI.iconSize, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: UI.buttonSize, height: UI.buttonSize)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Settings")

                    Button(action: onShowTabs) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.primary, lineWidth: 2)
                                .frame(width: 16, height: 12)
                            if tabCount <= 9 {
                                Text("\(tabCount)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.primary)
                            } else {
                                Text("∞")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                        }
                        .frame(width: UI.buttonSize, height: UI.buttonSize)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Tabs")
                }
            }
            .padding(.horizontal, UI.toolbarHPadding)
            .padding(.vertical, UI.toolbarVPadding)

            if isLoading {
                Rectangle()
                    .fill(Color.blue)
                    .frame(height: 2)
                    .animation(.easeInOut(duration: 0.3), value: isLoading)
            }
        }
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        )
    }
}
