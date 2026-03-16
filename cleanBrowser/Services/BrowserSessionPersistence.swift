import Foundation

struct BrowserSessionState: Equatable {
    struct TabRecord: Codable, Equatable {
        let url: String
        let title: String
    }

    let tabs: [TabRecord]
    let activeTabIndex: Int
    let confirmNavigation: Bool
    let isMutedGlobal: Bool
    let customKeyboardEnabled: Bool
}

protocol BrowserSessionPersisting {
    func load() -> BrowserSessionState
    func save(_ state: BrowserSessionState)
}

final class UserDefaultsBrowserSessionPersistence: BrowserSessionPersisting {
    private let userDefaults: UserDefaults
    private let tabsKey = "SavedTabs"
    private let activeTabIndexKey = "ActiveTabIndex"
    private let confirmNavigationKey = "ConfirmNavigationEnabled"
    private let isMutedGlobalKey = "GlobalMuted"
    private let customKeyboardEnabledKey = "CustomKeyboardEnabled"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> BrowserSessionState {
        let storedTabs = (userDefaults.array(forKey: tabsKey) as? [[String: String]] ?? [])
            .compactMap { record -> BrowserSessionState.TabRecord? in
                guard let url = record["url"], let title = record["title"] else { return nil }
                return BrowserSessionState.TabRecord(url: url, title: title)
            }

        return BrowserSessionState(
            tabs: storedTabs,
            activeTabIndex: userDefaults.integer(forKey: activeTabIndexKey),
            confirmNavigation: userDefaults.object(forKey: confirmNavigationKey) != nil
                ? userDefaults.bool(forKey: confirmNavigationKey)
                : true,
            isMutedGlobal: userDefaults.bool(forKey: isMutedGlobalKey),
            customKeyboardEnabled: userDefaults.object(forKey: customKeyboardEnabledKey) != nil
                ? userDefaults.bool(forKey: customKeyboardEnabledKey)
                : true
        )
    }

    func save(_ state: BrowserSessionState) {
        let tabsData = state.tabs.map { ["url": $0.url, "title": $0.title] }

        userDefaults.set(tabsData, forKey: tabsKey)
        userDefaults.set(state.activeTabIndex, forKey: activeTabIndexKey)
        userDefaults.set(state.confirmNavigation, forKey: confirmNavigationKey)
        userDefaults.set(state.isMutedGlobal, forKey: isMutedGlobalKey)
        userDefaults.set(state.customKeyboardEnabled, forKey: customKeyboardEnabledKey)
    }
}
