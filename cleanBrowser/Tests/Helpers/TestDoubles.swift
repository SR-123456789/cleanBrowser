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
