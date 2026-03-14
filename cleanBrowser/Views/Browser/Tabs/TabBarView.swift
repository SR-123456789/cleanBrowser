import SwiftUI

struct TabBarView: View {
    @ObservedObject var browserStore: BrowserStore
    
    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(browserStore.tabs.enumerated()), id: \.element.id) { index, tab in
                        BrowserTabChipView(
                            tab: tab,
                            isActive: index == browserStore.activeTabIndex,
                            onTap: {
                                browserStore.switchToTab(at: index)
                            },
                            onClose: {
                                browserStore.closeTab(at: index)
                            }
                        )
                    }
                }
                .padding(.horizontal, 8)
            }
            
            // 新しいタブボタン
            Button(action: {
                browserStore.addNewTab()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 28, height: 28)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Circle())
            }
            .padding(.trailing, 8)
        }
        .frame(height: 36)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        )
    }
}

#Preview {
    TabBarView(browserStore: BrowserStore())
}
