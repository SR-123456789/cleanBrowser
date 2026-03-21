import Foundation
import PostHog

enum AnalyticsKeyboardMode: String, Equatable {
    case system
    case custom

    init(customKeyboardEnabled: Bool) {
        self = customKeyboardEnabled ? .custom : .system
    }
}

protocol AnalyticsTracking: AnyObject {
    func trackAppOpened(appVersion: String, keyboardMode: AnalyticsKeyboardMode)
    func trackAdDialogShown()
    func trackAdDialogViewed()
    func trackKeyboardChoiceDialogShown()
    func trackKeyboardChoiceSelected(_ keyboardMode: AnalyticsKeyboardMode)
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
