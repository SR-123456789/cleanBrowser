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
    @Published var isMuted: Bool = false // 追加: タブごとのミュート状態
    
    init(url: String = "https://www.google.com") {
        self.url = url
    }
}

// タブを管理するクラス
class TabManager: ObservableObject {
    static let shared = TabManager()
    
    @Published var tabs: [BrowserTab] = []
    @Published var activeTabIndex: Int = 0 {
        didSet {
            updateActiveTab()
            saveTabs()
        }
    }
    @Published var activeTab: BrowserTab? = nil
    @Published var showTabOverview: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let tabsKey = "SavedTabs"
    private let activeTabIndexKey = "ActiveTabIndex"
    
    private init() {
        loadTabs()
        if tabs.isEmpty {
            addNewTab()
        }
    }
    
    func addNewTab(url: String = "https://www.google.com") {
        let newTab = BrowserTab(url: url)
        tabs.append(newTab)
        activeTabIndex = tabs.count - 1
        updateActiveTab()
        saveTabs()
    }
        
    func closeTab(at index: Int) {
        guard index < tabs.count && tabs.count > 1 else { return }
        
        tabs.remove(at: index)
        
        if activeTabIndex >= tabs.count {
            activeTabIndex = tabs.count - 1
        } else if activeTabIndex > index {
            activeTabIndex -= 1
        }
        updateActiveTab()
        saveTabs()
    }
    
    func switchToTab(at index: Int) {
        print("Switching to tab at index \(index)")
        guard index < tabs.count else { return }
        activeTabIndex = index
        print("Active tab index is now \(activeTabIndex)")
    }
    
    private func updateActiveTab() {
        activeTab = (activeTabIndex < tabs.count) ? tabs[activeTabIndex] : nil
    }
    
    // タブの状態を保存
    func saveTabs() {
        let tabsData = tabs.map { tab in
            ["url": tab.url, "title": tab.title]
        }
        
        userDefaults.set(tabsData, forKey: tabsKey)
        userDefaults.set(activeTabIndex, forKey: activeTabIndexKey)
        userDefaults.synchronize() // 即座に保存を実行
    }
    
    // タブの状態を復元
    private func loadTabs() {
        guard let tabsData = userDefaults.array(forKey: tabsKey) as? [[String: String]] else {
            return
        }
        
        tabs = tabsData.compactMap { data in
            guard let url = data["url"], let title = data["title"] else { return nil }
            let tab = BrowserTab(url: url)
            tab.title = title
            return tab
        }
        
        activeTabIndex = userDefaults.integer(forKey: activeTabIndexKey)
        if activeTabIndex >= tabs.count {
            activeTabIndex = max(0, tabs.count - 1)
        }
        
        updateActiveTab()
    }
}
