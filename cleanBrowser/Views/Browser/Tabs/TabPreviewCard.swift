import SwiftUI

struct TabPreviewCard: View {
    @ObservedObject var tab: BrowserTab
    let isActive: Bool
    let onTap: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Rectangle()
                    .fill(Color(.systemBackground))
                    .aspectRatio(3/4, contentMode: .fit)

                if let webView = tab.webView {
                    WebViewSnapshot(webView: webView)
                        .aspectRatio(3/4, contentMode: .fit)
                        .clipped()
                } else {
                    VStack {
                        Image(systemName: "globe")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("読み込み中...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                VStack {
                    HStack {
                        Spacer()
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.primary)
                                .frame(width: 24, height: 24)
                                .background(Color(.systemBackground))
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        .padding(8)
                    }
                    Spacer()
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: tab.url.hasPrefix("https://") ? "lock.fill" : "globe")
                        .font(.system(size: 12))
                        .foregroundColor(tab.url.hasPrefix("https://") ? .green : .secondary)

                    Text(tab.title.isEmpty ? "新しいタブ" : tab.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Text(BrowserURLResolver.displayText(for: tab.url))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .scaleEffect(isActive ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isActive)
        .onTapGesture {
            onTap()
        }
    }
}
