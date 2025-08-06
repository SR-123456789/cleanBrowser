//
//  TabManager.swift
//  cleanBrowser
//
//  Created by NakataniSoshi on 2025/08/07.
//

import SwiftUI
import WebKit

// タブの情報を管理するクラス
class BrowserTab: ObservableObject, Identifiable {
    let id = UUID()
    @Published var webView: WKWebView?
    @Published var title: String = "新しいタブ"
    @Published var url: String = "https://www.google.com"
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isLoading: Bool = false
    
    init(url: String = "https://www.google.com") {
        self.url = url
    }
}

// タブを管理するクラス
class TabManager: ObservableObject {
    @Published var tabs: [BrowserTab] = []
    @Published var activeTabIndex: Int = 0
    @Published var showTabOverview: Bool = false
    
    var activeTab: BrowserTab? {
        guard !tabs.isEmpty && activeTabIndex < tabs.count else { return nil }
        return tabs[activeTabIndex]
    }
    
    init() {
        addNewTab()
    }
    
    func addNewTab(url: String = "https://www.google.com") {
        let newTab = BrowserTab(url: url)
        tabs.append(newTab)
        activeTabIndex = tabs.count - 1
    }
    
    func closeTab(at index: Int) {
        guard index < tabs.count && tabs.count > 1 else { return }
        
        tabs.remove(at: index)
        
        if activeTabIndex >= tabs.count {
            activeTabIndex = tabs.count - 1
        } else if activeTabIndex > index {
            activeTabIndex -= 1
        }
    }
    
    func switchToTab(at index: Int) {
        guard index < tabs.count else { return }
        activeTabIndex = index
    }
}
