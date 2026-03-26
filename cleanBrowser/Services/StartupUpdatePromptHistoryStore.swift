import Foundation

protocol StartupUpdatePromptHistoryStoring {
    func hasShownPrompt(appVersion: String, message: String) -> Bool
    func markPromptShown(appVersion: String, message: String)
}

final class UserDefaultsStartupUpdatePromptHistoryStore: StartupUpdatePromptHistoryStoring {
    private let defaults: UserDefaults
    private let historyKey = "startup.update_prompt_history"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func hasShownPrompt(appVersion: String, message: String) -> Bool {
        promptHistory().contains(historyEntry(appVersion: appVersion, message: message))
    }

    func markPromptShown(appVersion: String, message: String) {
        var history = promptHistory()
        history.insert(historyEntry(appVersion: appVersion, message: message))
        defaults.set(Array(history).sorted(), forKey: historyKey)
    }

    private func promptHistory() -> Set<String> {
        Set(defaults.stringArray(forKey: historyKey) ?? [])
    }

    private func historyEntry(appVersion: String, message: String) -> String {
        appVersion + "\n" + message
    }
}
