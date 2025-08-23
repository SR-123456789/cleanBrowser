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
    // アプリ全体のミュート状態（全タブ共通）
    @Published var isMutedGlobal: Bool = false
    // URL移動前の確認ダイアログ（アプリ全体設定）
    // デフォルト: 有効 (true)。既に保存された設定があればそれを使用。
    @Published var confirmNavigation: Bool = true {
        didSet {
            userDefaults.set(confirmNavigation, forKey: confirmNavigationKey)
        }
    }
    @Published var activeTabIndex: Int = 0 {
        didSet {
            updateActiveTab()
            saveTabs()
        }
    }
    @Published var activeTab: BrowserTab? = nil
    @Published var showTabOverview: Bool = false
    // 独自キーボードを使うかどうか（デフォルトOFF）
    @Published var customKeyboardEnabled: Bool = false {
        didSet {
            userDefaults.set(customKeyboardEnabled, forKey: customKeyboardEnabledKey)
            // 既存のwebViewにフラグを伝搬
            let js = "window.__useCustomKeyboard = " + (customKeyboardEnabled ? "true" : "false") + ";"
            for tab in tabs {
                tab.webView?.evaluateJavaScript(js, completionHandler: nil)
            }
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private let tabsKey = "SavedTabs"
    private let activeTabIndexKey = "ActiveTabIndex"
    private let confirmNavigationKey = "ConfirmNavigationEnabled"
    private let isMutedGlobalKey = "GlobalMuted"
    private let customKeyboardEnabledKey = "CustomKeyboardEnabled"
    
    private init() {
        loadTabs()
        if tabs.isEmpty {
            addNewTab()
        }
        // 設定の読み込み: 保存済みのキーが無ければデフォルト(true)を維持
        if userDefaults.object(forKey: confirmNavigationKey) != nil {
            self.confirmNavigation = userDefaults.bool(forKey: confirmNavigationKey)
        }
        self.isMutedGlobal = userDefaults.bool(forKey: isMutedGlobalKey)
        // customKeyboard の読み込み（保存済みがあれば使用、なければデフォルト true）
        if userDefaults.object(forKey: customKeyboardEnabledKey) != nil {
            self.customKeyboardEnabled = userDefaults.bool(forKey: customKeyboardEnabledKey)
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

    // 全タブにミュート設定を適用
    func applyMuteToAllTabs(_ muted: Bool) {
        isMutedGlobal = muted
    userDefaults.set(muted, forKey: isMutedGlobalKey)
        let js = WebViewRepresentable.muteJS(muted)
        for tab in tabs {
            tab.isMuted = muted // 互換性のため更新（将来的に削除可）
            tab.webView?.evaluateJavaScript(js, completionHandler: nil)
        }
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
