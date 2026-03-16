import Foundation
import PostHog

protocol AnalyticsTracking: AnyObject {
    func trackAppOpened()
    func trackAdDialogShown()
}

final class AnalyticsManager: AnalyticsTracking {
    private enum Constants {
//        static let projectToken = "phc_lelswm7h3ZOMJtBK71Fy8yiqZhIT1Oy6jWvCZiHWx3"
        
        static let projectToken = "test_token" // ←あとで本番のトークンに

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

    private func configureIfNeeded() {
        guard !isConfigured else { return }

        let configuration = PostHogConfig(
            apiKey: Constants.projectToken,
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
}

final class NoopAnalyticsManager: AnalyticsTracking {
    func trackAppOpened() {}
    func trackAdDialogShown() {}
}
