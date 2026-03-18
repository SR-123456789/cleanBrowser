import SwiftUI
import WebKit

@MainActor
final class BrowserStore: ObservableObject {
    @Published private(set) var tabs: [BrowserTab]
    @Published var isMutedGlobal: Bool {
        didSet {
            guard !isRestoringState else { return }
            persistSession()
        }
    }
    @Published var confirmNavigation: Bool {
        didSet {
            guard !isRestoringState else { return }
            persistSession()
        }
    }
    @Published var activeTabIndex: Int {
        didSet {
            guard !isRestoringState else { return }
            updateActiveTab()
            persistSession()
        }
    }
    @Published private(set) var activeTab: BrowserTab?
    @Published var customKeyboardEnabled: Bool {
        didSet {
            guard !isRestoringState else { return }
            propagateCustomKeyboardPreference()
            persistSession()
        }
    }

    private let persistence: any BrowserSessionPersisting
    private let persistDebounceInterval: TimeInterval
    private let scheduleDelayedWork: @MainActor (TimeInterval, DispatchWorkItem) -> Void
    private var isRestoringState = false
    private var pendingPersistWorkItem: DispatchWorkItem?

    init(
        persistence: any BrowserSessionPersisting = UserDefaultsBrowserSessionPersistence(),
        persistDebounceInterval: TimeInterval = 0.75,
        scheduleDelayedWork: @escaping @MainActor (TimeInterval, DispatchWorkItem) -> Void = { delay, workItem in
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    ) {
        self.persistence = persistence
        self.persistDebounceInterval = persistDebounceInterval
        self.scheduleDelayedWork = scheduleDelayedWork

        let state = persistence.load()
        let restoredTabs = state.tabs.map { record in
            BrowserTab(url: record.url, title: record.title)
        }

        self.tabs = restoredTabs.isEmpty ? [BrowserTab(url: BrowserURLResolver.defaultHomePage)] : restoredTabs
        self.isMutedGlobal = state.isMutedGlobal
        self.confirmNavigation = state.confirmNavigation
        self.customKeyboardEnabled = state.customKeyboardEnabled
        self.activeTabIndex = 0
        self.activeTab = nil

        restoreActiveTabIndex(from: state.activeTabIndex)
        applyInitialMuteState()
        bindTabStateObservers()
    }

    func addNewTab(
        url: String = BrowserURLResolver.defaultHomePage,
        openerTabID: UUID? = nil,
        creationSource: BrowserTabCreationSource = .manual
    ) {
        let newTab = BrowserTab(
            url: url,
            openerTabID: openerTabID,
            creationSource: creationSource
        )
        tabs.append(newTab)
        bindTabStateObservers()
        activeTabIndex = tabs.count - 1
        updateActiveTab()
        persistSession()
    }

    func closeTab(at index: Int) {
        guard tabs.indices.contains(index), tabs.count > 1 else { return }
        tabs[index].teardownWebView()
        tabs.remove(at: index)
        bindTabStateObservers()

        if activeTabIndex >= tabs.count {
            activeTabIndex = tabs.count - 1
        } else if activeTabIndex > index {
            activeTabIndex -= 1
        } else {
            updateActiveTab()
            persistSession()
        }
    }

    func switchToTab(at index: Int) {
        guard tabs.indices.contains(index) else { return }
        activeTabIndex = index
    }

    func switchToTab(withID id: UUID) {
        guard let index = index(of: id) else { return }
        switchToTab(at: index)
    }

    func index(of id: UUID) -> Int? {
        tabs.firstIndex { $0.id == id }
    }

    func toggleGlobalMute() {
        applyMuteToAllTabs(!isMutedGlobal)
    }

    func applyMuteToAllTabs(_ muted: Bool) {
        isMutedGlobal = muted
        let script = WebViewJS.muteScript(muted)
        for tab in tabs {
            tab.setMutedIfNeeded(muted)
            tab.webView?.evaluateJavaScript(script, completionHandler: nil)
        }
    }

    func applyRuntimePreferences(to webView: WKWebView) {
        if isMutedGlobal {
            webView.evaluateJavaScript(WebViewJS.muteScript(true), completionHandler: nil)
        }

        let confirmNavigationJS = "window.__confirmNavOn = \(confirmNavigation ? "true" : "false");"
        webView.evaluateJavaScript(confirmNavigationJS, completionHandler: nil)

        let customKeyboardJS = "window.__useCustomKeyboard = \(customKeyboardEnabled ? "true" : "false");"
        webView.evaluateJavaScript(customKeyboardJS, completionHandler: nil)

        if !customKeyboardEnabled {
            webView.evaluateJavaScript(WebViewJS.restoreNativeKeyboardScript, completionHandler: nil)
        }
    }

    func shouldConfirmNavigation(current: URL?, target: URL, sourceHost: String?) -> Bool {
        if let current, current.host?.lowercased() == target.host?.lowercased() {
            return false
        }

        if isSearchEngineHost(sourceHost) {
            return false
        }

        return true
    }

    func persistCurrentSession() {
        guard !isRestoringState else { return }
        flushPendingPersist()
        persistSession()
    }

    private func restoreActiveTabIndex(from storedIndex: Int) {
        isRestoringState = true
        activeTabIndex = min(max(storedIndex, 0), tabs.count - 1)
        isRestoringState = false
        updateActiveTab()
    }

    private func updateActiveTab() {
        activeTab = tabs.indices.contains(activeTabIndex) ? tabs[activeTabIndex] : nil
    }

    private func persistSession() {
        let state = BrowserSessionState(
            tabs: tabs.map { BrowserSessionState.TabRecord(url: $0.url, title: $0.title) },
            activeTabIndex: activeTabIndex,
            confirmNavigation: confirmNavigation,
            isMutedGlobal: isMutedGlobal,
            customKeyboardEnabled: customKeyboardEnabled
        )
        persistence.save(state)
    }

    private func bindTabStateObservers() {
        for tab in tabs {
            tab.onPersistableStateChange = { [weak self] in
                self?.scheduleDebouncedPersist()
            }
        }
    }

    private func scheduleDebouncedPersist() {
        guard !isRestoringState else { return }

        pendingPersistWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.persistCurrentSession()
        }
        pendingPersistWorkItem = workItem
        scheduleDelayedWork(persistDebounceInterval, workItem)
    }

    private func flushPendingPersist() {
        pendingPersistWorkItem?.cancel()
        pendingPersistWorkItem = nil
    }

    private func propagateCustomKeyboardPreference() {
        let script = "window.__useCustomKeyboard = \(customKeyboardEnabled ? "true" : "false");"
        for tab in tabs {
            tab.webView?.evaluateJavaScript(script, completionHandler: nil)
        }
    }

    private func applyInitialMuteState() {
        guard isMutedGlobal else { return }
        tabs.forEach { $0.setMutedIfNeeded(true) }
    }

    private func isSearchEngineHost(_ host: String?) -> Bool {
        guard let normalizedHost = host?.lowercased() else { return false }

        return normalizedHost == "www.google.com"
            || normalizedHost == "google.com"
            || normalizedHost.hasSuffix(".google.com")
            || normalizedHost == "www.bing.com"
            || normalizedHost == "bing.com"
            || normalizedHost == "search.yahoo.co.jp"
            || normalizedHost == "yahoo.co.jp"
            || normalizedHost.hasSuffix(".yahoo.co.jp")
    }
}

typealias TabManager = BrowserStore
