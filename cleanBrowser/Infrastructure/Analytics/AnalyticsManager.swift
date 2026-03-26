import Foundation
import PostHog

enum AnalyticsKeyboardMode: String, Equatable {
    case system
    case custom

    init(customKeyboardEnabled: Bool) {
        self = customKeyboardEnabled ? .custom : .system
    }
}

enum StartupLoadErrorType: String, Equatable {
    case configuration
    case network
    case httpStatus = "http_status"
    case decoding
    case unknown
}

enum StartupUpdateType: String, Equatable {
    case mandatory
    case recommended
}

enum StartupUpdatePromptAction: String, Equatable {
    case openStore = "open_store"
    case dismiss
}

protocol AnalyticsTracking: AnyObject {
    func trackAppOpened(appVersion: String, keyboardMode: AnalyticsKeyboardMode)
    func trackAdDialogShown()
    func trackAdDialogViewed()
    func trackKeyboardChoiceDialogShown()
    func trackKeyboardChoiceSelected(_ keyboardMode: AnalyticsKeyboardMode)
    func trackStartupLoaded(
        appVersion: String,
        mustUpdate: Bool,
        shouldUpdate: Bool,
        repeatUpdatePrompt: Bool,
        dailyInterstitialIsShow: Bool,
        updateLinkPresent: Bool
    )
    func trackStartupLoadFailed(
        appVersion: String,
        errorType: StartupLoadErrorType,
        httpStatus: Int?,
        adsHiddenOnFailure: Bool
    )
    func trackStartupUpdatePromptShown(
        appVersion: String,
        updateType: StartupUpdateType,
        repeatUpdatePrompt: Bool,
        updateLinkPresent: Bool,
        message: String
    )
    func trackStartupUpdatePromptAction(
        appVersion: String,
        updateType: StartupUpdateType,
        action: StartupUpdatePromptAction
    )
}

final class AnalyticsManager: AnalyticsTracking {
    private enum InfoKeys {
        static let projectToken = "PostHogProjectToken"
    }

    private enum Constants {
        static let host = "https://us.i.posthog.com"
    }

    private let deviceIdProvider: any DeviceIdProviding
    private var isConfigured = false

    init(deviceIdProvider: any DeviceIdProviding = IdentifierForVendorDeviceIdProvider()) {
        self.deviceIdProvider = deviceIdProvider
    }

    func trackAppOpened(appVersion: String, keyboardMode: AnalyticsKeyboardMode) {
        capture(
            "app_opened",
            properties: [
                "app_version": appVersion,
                "keyboard_mode": keyboardMode.rawValue,
            ]
        )
    }

    func trackAdDialogShown() {
        capture("ad_dialog_shown")
    }

    func trackAdDialogViewed() {
        capture("ad_dialog_viewed")
    }

    func trackKeyboardChoiceDialogShown() {
        capture("keyboard_choice_dialog_shown")
    }

    func trackKeyboardChoiceSelected(_ keyboardMode: AnalyticsKeyboardMode) {
        capture(
            "keyboard_choice_selected",
            properties: [
                "keyboard_mode": keyboardMode.rawValue,
            ]
        )
    }

    func trackStartupLoaded(
        appVersion: String,
        mustUpdate: Bool,
        shouldUpdate: Bool,
        repeatUpdatePrompt: Bool,
        dailyInterstitialIsShow: Bool,
        updateLinkPresent: Bool
    ) {
        capture(
            "startup_loaded",
            properties: [
                "app_version": appVersion,
                "must_update": mustUpdate,
                "should_update": shouldUpdate,
                "repeat_update_prompt": repeatUpdatePrompt,
                "daily_interstitial_is_show": dailyInterstitialIsShow,
                "update_link_present": updateLinkPresent,
            ]
        )
    }

    func trackStartupLoadFailed(
        appVersion: String,
        errorType: StartupLoadErrorType,
        httpStatus: Int?,
        adsHiddenOnFailure: Bool
    ) {
        var properties: [String: Any] = [
            "app_version": appVersion,
            "error_type": errorType.rawValue,
            "ads_hidden_on_failure": adsHiddenOnFailure,
        ]

        if let httpStatus {
            properties["http_status"] = httpStatus
        }

        capture("startup_load_failed", properties: properties)
    }

    func trackStartupUpdatePromptShown(
        appVersion: String,
        updateType: StartupUpdateType,
        repeatUpdatePrompt: Bool,
        updateLinkPresent: Bool,
        message: String
    ) {
        capture(
            "startup_update_prompt_shown",
            properties: [
                "app_version": appVersion,
                "update_type": updateType.rawValue,
                "repeat_update_prompt": repeatUpdatePrompt,
                "update_link_present": updateLinkPresent,
                "message": message,
            ]
        )
    }

    func trackStartupUpdatePromptAction(
        appVersion: String,
        updateType: StartupUpdateType,
        action: StartupUpdatePromptAction
    ) {
        capture(
            "startup_update_prompt_action",
            properties: [
                "app_version": appVersion,
                "update_type": updateType.rawValue,
                "action": action.rawValue,
            ]
        )
    }

    private func capture(_ event: String, properties: [String: Any]? = nil) {
        configureIfNeeded()
        PostHogSDK.shared.capture(event, properties: properties)
    }

    private func configureIfNeeded() {
        guard !isConfigured else { return }
        guard let projectToken = configuredProjectToken else {
            assertionFailure("Missing PostHogProjectToken in Info.plist")
            return
        }

        let configuration = PostHogConfig(
            apiKey: projectToken,
            host: Constants.host
        )
        configuration.captureApplicationLifecycleEvents = false
        configuration.captureScreenViews = false
        configuration.captureElementInteractions = false
        configuration.preloadFeatureFlags = false
        configuration.sendFeatureFlagEvent = false
        configuration.sessionReplay = false
        configuration.enableSwizzling = false
        if #available(iOS 15.0, *) {
            configuration.surveys = false
        }

        PostHogSDK.shared.setup(configuration)
        PostHogSDK.shared.identify(deviceIdProvider.distinctId())
        isConfigured = true
    }

    private var configuredProjectToken: String? {
        let rawValue = (Bundle.main.object(forInfoDictionaryKey: InfoKeys.projectToken) as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return rawValue.isEmpty ? nil : rawValue
    }
}

final class NoopAnalyticsManager: AnalyticsTracking {
    func trackAppOpened(appVersion: String, keyboardMode: AnalyticsKeyboardMode) {}
    func trackAdDialogShown() {}
    func trackAdDialogViewed() {}
    func trackKeyboardChoiceDialogShown() {}
    func trackKeyboardChoiceSelected(_ keyboardMode: AnalyticsKeyboardMode) {}
    func trackStartupLoaded(
        appVersion: String,
        mustUpdate: Bool,
        shouldUpdate: Bool,
        repeatUpdatePrompt: Bool,
        dailyInterstitialIsShow: Bool,
        updateLinkPresent: Bool
    ) {}
    func trackStartupLoadFailed(
        appVersion: String,
        errorType: StartupLoadErrorType,
        httpStatus: Int?,
        adsHiddenOnFailure: Bool
    ) {}
    func trackStartupUpdatePromptShown(
        appVersion: String,
        updateType: StartupUpdateType,
        repeatUpdatePrompt: Bool,
        updateLinkPresent: Bool,
        message: String
    ) {}
    func trackStartupUpdatePromptAction(
        appVersion: String,
        updateType: StartupUpdateType,
        action: StartupUpdatePromptAction
    ) {}
}

extension Bundle {
    var cleanBrowserAppVersion: String {
        let marketingVersion = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let buildNumber = object(forInfoDictionaryKey: "CFBundleVersion") as? String

        if let marketingVersion, !marketingVersion.isEmpty {
            return marketingVersion
        }

        if let buildNumber, !buildNumber.isEmpty {
            return buildNumber
        }

        return "unknown"
    }
}
