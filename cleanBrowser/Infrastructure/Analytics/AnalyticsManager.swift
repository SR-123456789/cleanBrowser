import Foundation
import PostHog

protocol AnalyticsTracking: AnyObject {
    func trackAppOpened()
    func trackAdDialogShown()
    func trackAdDialogViewed()
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

    func trackAppOpened() {
        configureIfNeeded()
        PostHogSDK.shared.capture("app_opened")
    }

    func trackAdDialogShown() {
        configureIfNeeded()
        PostHogSDK.shared.capture("ad_dialog_shown")
    }

    func trackAdDialogViewed() {
        configureIfNeeded()
        PostHogSDK.shared.capture("ad_dialog_viewed")
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
    func trackAppOpened() {}
    func trackAdDialogShown() {}
    func trackAdDialogViewed() {}
}
