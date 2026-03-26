import Foundation
@testable import cleanBrowser

enum TestError: Error {
    case expectedFailure
}

final class BrowserSessionPersistenceSpy: BrowserSessionPersisting {
    var loadedState: BrowserSessionState
    private(set) var savedStates: [BrowserSessionState] = []
    var onSave: ((BrowserSessionState) -> Void)?

    init(loadedState: BrowserSessionState) {
        self.loadedState = loadedState
    }

    func load() -> BrowserSessionState {
        loadedState
    }

    func save(_ state: BrowserSessionState) {
        savedStates.append(state)
        onSave?(state)
    }
}

final class PINServiceStub: PINManaging {
    var isFirstLaunch: Bool
    var hasPINSet: Bool
    var expectedPIN: String
    private(set) var updatedPINs: [String] = []

    init(
        isFirstLaunch: Bool = false,
        hasPINSet: Bool = true,
        expectedPIN: String = "1234"
    ) {
        self.isFirstLaunch = isFirstLaunch
        self.hasPINSet = hasPINSet
        self.expectedPIN = expectedPIN
    }

    func verifyPIN(_ pin: String) -> Bool {
        pin == expectedPIN
    }

    func updatePIN(_ newPIN: String) {
        updatedPINs.append(newPIN)
        expectedPIN = newPIN
        hasPINSet = true
        isFirstLaunch = false
    }
}

@MainActor
final class StartupAdVisibilityControllerSpy: StartupAdVisibilityControlling {
    var isDailyInterstitialVisible: Bool = true
}

final class StartupLoaderStub: StartupLoading {
    var response: StartupResponse?
    var error: Error?
    private(set) var requestedAppVersions: [String] = []

    func fetchStartup(appVersion: String) async throws -> StartupResponse {
        requestedAppVersions.append(appVersion)

        if let error {
            throw error
        }

        return response ?? StartupResponse(
            update: StartupUpdateResponse(
                mustUpdate: false,
                shouldUpdate: false,
                repeatUpdatePrompt: false,
                updateLink: "https://apps.apple.com/app/id1234567890",
                message: "現在のバージョンは最新です。"
            ),
            ads: [
                StartupAdVisibilityResponse(
                    adID: "daily_interstitial",
                    isShow: true
                )
            ]
        )
    }
}

final class StartupUpdatePromptHistoryStoreStub: StartupUpdatePromptHistoryStoring {
    var shownKeys = Set<String>()
    private(set) var markedEntries: [(appVersion: String, message: String)] = []

    func hasShownPrompt(appVersion: String, message: String) -> Bool {
        shownKeys.contains(historyKey(appVersion: appVersion, message: message))
    }

    func markPromptShown(appVersion: String, message: String) {
        markedEntries.append((appVersion, message))
        shownKeys.insert(historyKey(appVersion: appVersion, message: message))
    }

    private func historyKey(appVersion: String, message: String) -> String {
        appVersion + "\n" + message
    }
}

@MainActor
final class StartupAnalyticsTrackerStub: AnalyticsTracking {
    struct StartupLoadedCall: Equatable {
        let appVersion: String
        let mustUpdate: Bool
        let shouldUpdate: Bool
        let repeatUpdatePrompt: Bool
        let dailyInterstitialIsShow: Bool
        let updateLinkPresent: Bool
    }

    struct StartupLoadFailedCall: Equatable {
        let appVersion: String
        let errorType: StartupLoadErrorType
        let httpStatus: Int?
        let adsHiddenOnFailure: Bool
    }

    struct StartupUpdatePromptShownCall: Equatable {
        let appVersion: String
        let updateType: StartupUpdateType
        let repeatUpdatePrompt: Bool
        let updateLinkPresent: Bool
        let message: String
    }

    struct StartupUpdatePromptActionCall: Equatable {
        let appVersion: String
        let updateType: StartupUpdateType
        let action: StartupUpdatePromptAction
    }

    private(set) var appOpenedParameters: [(String, AnalyticsKeyboardMode)] = []
    private(set) var adDialogShownCount = 0
    private(set) var adDialogViewedCount = 0
    private(set) var keyboardChoiceDialogShownCount = 0
    private(set) var selectedKeyboardModes: [AnalyticsKeyboardMode] = []
    private(set) var startupLoadedCalls: [StartupLoadedCall] = []
    private(set) var startupLoadFailedCalls: [StartupLoadFailedCall] = []
    private(set) var startupUpdatePromptShownCalls: [StartupUpdatePromptShownCall] = []
    private(set) var startupUpdatePromptActionCalls: [StartupUpdatePromptActionCall] = []

    func trackAppOpened(appVersion: String, keyboardMode: AnalyticsKeyboardMode) {
        appOpenedParameters.append((appVersion, keyboardMode))
    }

    func trackAdDialogShown() {
        adDialogShownCount += 1
    }

    func trackAdDialogViewed() {
        adDialogViewedCount += 1
    }

    func trackKeyboardChoiceDialogShown() {
        keyboardChoiceDialogShownCount += 1
    }

    func trackKeyboardChoiceSelected(_ keyboardMode: AnalyticsKeyboardMode) {
        selectedKeyboardModes.append(keyboardMode)
    }

    func trackStartupLoaded(
        appVersion: String,
        mustUpdate: Bool,
        shouldUpdate: Bool,
        repeatUpdatePrompt: Bool,
        dailyInterstitialIsShow: Bool,
        updateLinkPresent: Bool
    ) {
        startupLoadedCalls.append(
            .init(
                appVersion: appVersion,
                mustUpdate: mustUpdate,
                shouldUpdate: shouldUpdate,
                repeatUpdatePrompt: repeatUpdatePrompt,
                dailyInterstitialIsShow: dailyInterstitialIsShow,
                updateLinkPresent: updateLinkPresent
            )
        )
    }

    func trackStartupLoadFailed(
        appVersion: String,
        errorType: StartupLoadErrorType,
        httpStatus: Int?,
        adsHiddenOnFailure: Bool
    ) {
        startupLoadFailedCalls.append(
            .init(
                appVersion: appVersion,
                errorType: errorType,
                httpStatus: httpStatus,
                adsHiddenOnFailure: adsHiddenOnFailure
            )
        )
    }

    func trackStartupUpdatePromptShown(
        appVersion: String,
        updateType: StartupUpdateType,
        repeatUpdatePrompt: Bool,
        updateLinkPresent: Bool,
        message: String
    ) {
        startupUpdatePromptShownCalls.append(
            .init(
                appVersion: appVersion,
                updateType: updateType,
                repeatUpdatePrompt: repeatUpdatePrompt,
                updateLinkPresent: updateLinkPresent,
                message: message
            )
        )
    }

    func trackStartupUpdatePromptAction(
        appVersion: String,
        updateType: StartupUpdateType,
        action: StartupUpdatePromptAction
    ) {
        startupUpdatePromptActionCalls.append(
            .init(
                appVersion: appVersion,
                updateType: updateType,
                action: action
            )
        )
    }
}
