import XCTest
@testable import cleanBrowser

@MainActor
final class BrowserViewModelTests: XCTestCase {
    func test_handleSystemKeyboardGuideRequested_showsGuideBeforeSecondSystemKeyboardSession() {
        let (sut, store, persistence, analytics) = makeSUT()

        sut.handleWebInputStateChange(.init(isFocused: true, usesCustomKeyboard: false))
        sut.handleWebInputStateChange(.init(isFocused: false, usesCustomKeyboard: false))
        sut.handleSystemKeyboardGuideRequested()

        XCTAssertEqual(store.systemKeyboardUseCount, 1)
        XCTAssertTrue(sut.showCustomKeyboardGuide)
        XCTAssertTrue(store.hasAcknowledgedCustomKeyboardGuide)
        XCTAssertFalse(store.shouldSuggestCustomKeyboardGuide)
        XCTAssertEqual(persistence.savedStates.last?.hasAcknowledgedCustomKeyboardGuide, true)
        XCTAssertEqual(analytics.keyboardChoiceDialogShownCount, 1)
    }

    func test_enableCustomKeyboardFromGuide_enablesCustomKeyboardAndHidesGuide() {
        let (sut, store, _, analytics) = makeSUT()
        sut.handleWebInputStateChange(.init(isFocused: true, usesCustomKeyboard: false))
        sut.handleWebInputStateChange(.init(isFocused: false, usesCustomKeyboard: false))
        sut.handleSystemKeyboardGuideRequested()

        sut.enableCustomKeyboardFromGuide()

        XCTAssertTrue(store.customKeyboardEnabled)
        XCTAssertTrue(store.hasAcknowledgedCustomKeyboardGuide)
        XCTAssertFalse(sut.showCustomKeyboardGuide)
        XCTAssertEqual(analytics.selectedKeyboardModes, [.custom])
    }

    func test_dismissCustomKeyboardGuide_acknowledgesGuideAndHidesIt() {
        let (sut, store, _, analytics) = makeSUT()
        sut.handleWebInputStateChange(.init(isFocused: true, usesCustomKeyboard: false))
        sut.handleWebInputStateChange(.init(isFocused: false, usesCustomKeyboard: false))
        sut.handleSystemKeyboardGuideRequested()

        sut.dismissCustomKeyboardGuide()

        XCTAssertTrue(store.hasAcknowledgedCustomKeyboardGuide)
        XCTAssertFalse(store.shouldSuggestCustomKeyboardGuide)
        XCTAssertFalse(sut.showCustomKeyboardGuide)
        XCTAssertEqual(analytics.selectedKeyboardModes, [.system])
    }

    func test_handleInterstitialPresentationChanged_suspendsWebViewsAndDismissesCustomKeyboard() {
        let (sut, store, _, _) = makeSUT(state: .init(
            tabs: [.init(url: BrowserURLResolver.defaultHomePage, title: "新しいタブ")],
            activeTabIndex: 0,
            confirmNavigation: true,
            isMutedGlobal: false,
            customKeyboardEnabled: true,
            systemKeyboardUseCount: 0,
            hasAcknowledgedCustomKeyboardGuide: false
        ))
        sut.isKeyboardVisible = true

        sut.handleInterstitialPresentationChanged(true)

        XCTAssertTrue(store.areWebViewsSuspendedForInterstitial)
        XCTAssertFalse(sut.isKeyboardVisible)

        sut.handleInterstitialPresentationChanged(false)

        XCTAssertFalse(store.areWebViewsSuspendedForInterstitial)
    }

    private func makeSUT(
        state: BrowserSessionState = .init(
            tabs: [.init(url: BrowserURLResolver.defaultHomePage, title: "新しいタブ")],
            activeTabIndex: 0,
            confirmNavigation: true,
            isMutedGlobal: false,
            customKeyboardEnabled: false,
            systemKeyboardUseCount: 0,
            hasAcknowledgedCustomKeyboardGuide: false
        )
    ) -> (BrowserViewModel, BrowserStore, BrowserSessionPersistenceSpy, BrowserAnalyticsTrackerStub) {
        let persistence = BrowserSessionPersistenceSpy(loadedState: state)
        let analytics = BrowserAnalyticsTrackerStub()
        let store = BrowserStore(
            persistence: persistence,
            persistDebounceInterval: 0,
            scheduleDelayedWork: { _, workItem in
                workItem.perform()
            }
        )

        return (
            BrowserViewModel(browserStore: store, analytics: analytics),
            store,
            persistence,
            analytics
        )
    }
}

@MainActor
private final class BrowserAnalyticsTrackerStub: AnalyticsTracking {
    private(set) var appOpenedParameters: [(String, AnalyticsKeyboardMode)] = []
    private(set) var adDialogShownCount = 0
    private(set) var adDialogViewedCount = 0
    private(set) var keyboardChoiceDialogShownCount = 0
    private(set) var selectedKeyboardModes: [AnalyticsKeyboardMode] = []

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
}
