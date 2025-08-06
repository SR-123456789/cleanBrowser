//
//  TabBarView.swift
//  cleanBrowser
//
//  Created by NakataniSoshi on 2025/08/07.
//

import SwiftUI

struct TabBarView: View {
    @ObservedObject var tabManager: TabManager
    
    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(tabManager.tabs.enumerated()), id: \.element.id) { index, tab in
                        TabView(
                            tab: tab,
                            isActive: index == tabManager.activeTabIndex,
                            onTap: {
                                tabManager.switchToTab(at: index)
                            },
                            onClose: {
                                tabManager.closeTab(at: index)
                            }
                        )
                    }
                }
                .padding(.horizontal, 8)
            }
            
            // 新しいタブボタン
            Button(action: {
                tabManager.addNewTab()
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

struct TabView: View {
    @ObservedObject var tab: BrowserTab
    let isActive: Bool
    let onTap: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(tab.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isActive ? .primary : .secondary)
                .lineLimit(1)
                .frame(maxWidth: 120)
            
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 16, height: 16)
                    .background(Color(.quaternarySystemFill))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? Color(.secondarySystemBackground) : Color(.tertiarySystemFill))
        )
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    TabBarView(tabManager: TabManager())
}