//
//  TabOverviewView.swift
//  cleanBrowser
//
//  Created by NakataniSoshi on 2025/08/07.
//

import SwiftUI
import WebKit

struct TabOverviewView: View {
    @ObservedObject var tabManager: TabManager
    @Binding var isPresented: Bool
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(tabManager.tabs.enumerated()), id: \.element.id) { index, tab in
                        TabPreviewCard(
                            tab: tab,
                            isActive: index == tabManager.activeTabIndex,
                            onTap: {
                                tabManager.switchToTab(at: index)
                                isPresented = false
                            },
                            onClose: {
                                tabManager.closeTab(at: index)
                            }
                        )
                    }
                }
                .padding(16)
            }
            .navigationTitle("\(tabManager.tabs.count)個のタブ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        tabManager.addNewTab()
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        isPresented = false
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct TabPreviewCard: View {
    @ObservedObject var tab: BrowserTab
    let isActive: Bool
    let onTap: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // WebViewプレビュー部分
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
                
                // 閉じるボタン
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
            
            // タブ情報部分
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    // サイトアイコン
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
                
                Text(formatURL(tab.url))
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
    
    private func formatURL(_ url: String) -> String {
        if let urlComponents = URLComponents(string: url) {
            return urlComponents.host ?? url
        }
        return url
    }
}

struct WebViewSnapshot: UIViewRepresentable {
    let webView: WKWebView
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.systemBackground
        
        // WebViewのスナップショットを取得
        webView.takeSnapshot(with: nil) { image, error in
            DispatchQueue.main.async {
                if let image = image {
                    let imageView = UIImageView(image: image)
                    imageView.contentMode = .scaleAspectFit
                    imageView.frame = containerView.bounds
                    imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    containerView.addSubview(imageView)
                }
            }
        }
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

#Preview {
    TabOverviewView(tabManager: TabManager(), isPresented: .constant(true))
}