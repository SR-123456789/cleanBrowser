import XCTest
@testable import cleanBrowser

@MainActor
final class DailyInterstitialGateViewModelTests: XCTestCase {
    func test_presentAd_startsPresentingInterstitialImmediately() {
        let store = DailyInterstitialGateStoreStub(
            state: DailyInterstitialGateState(
                dayKey: "2026-03-15",
                tapCount: DailyInterstitialGateState.tapThreshold,
                lastCompletedDayKey: nil
            )
        )
        let adService = InterstitialAdServiceStub()
        let sut = DailyInterstitialGateViewModel(stateStore: store, adService: adService)

        adService.sendState(isReady: true, isLoading: false, errorMessage: nil)

        sut.presentAd()

        XCTAssertGreaterThanOrEqual(adService.presentIfReadyCallCount, 1)
        XCTAssertTrue(sut.isAdPresenting)
    }

    func test_recordScreenTap_preparesInterstitialOnlyWhenThresholdIsFirstReached() {
        let store = DailyInterstitialGateStoreStub(
            state: DailyInterstitialGateState(
                dayKey: "2026-03-15",
                tapCount: DailyInterstitialGateState.tapThreshold - 1,
                lastCompletedDayKey: nil
            )
        )
        let adService = InterstitialAdServiceStub()
        let sut = DailyInterstitialGateViewModel(stateStore: store, adService: adService)

        sut.recordScreenTap()
        sut.recordScreenTap()
        sut.recordScreenTap()

        XCTAssertEqual(adService.prepareCalls.count, 1)
        XCTAssertEqual(store.state.tapCount, DailyInterstitialGateState.tapThreshold)
    }

    func test_prepareIfNeeded_doesNotLoadAdBeforePreloadThreshold() {
        let store = DailyInterstitialGateStoreStub(
            state: DailyInterstitialGateState(
                dayKey: "2026-03-15",
                tapCount: 0,
                lastCompletedDayKey: nil
            )
        )
        let adService = InterstitialAdServiceStub()
        let sut = DailyInterstitialGateViewModel(stateStore: store, adService: adService)

        sut.prepareIfNeeded(canShowPersonalizedAds: true)

        XCTAssertTrue(adService.prepareCalls.isEmpty)
    }

    func test_recordScreenTap_preloadsAdWhenCrossingPreloadThreshold() {
        let store = DailyInterstitialGateStoreStub(
            state: DailyInterstitialGateState(
                dayKey: "2026-03-15",
                tapCount: DailyInterstitialGateState.tapThreshold - 3,
                lastCompletedDayKey: nil
            )
        )
        let adService = InterstitialAdServiceStub()
        let sut = DailyInterstitialGateViewModel(stateStore: store, adService: adService)

        sut.recordScreenTap()

        XCTAssertEqual(adService.prepareCalls.count, 1)
        XCTAssertEqual(store.state.tapCount, DailyInterstitialGateState.tapThreshold - 2)
    }

    func test_prepareIfNeeded_onlyPreparesOncePerDayAutomatically() {
        let store = DailyInterstitialGateStoreStub(
            state: DailyInterstitialGateState(
                dayKey: "2026-03-15",
                tapCount: DailyInterstitialGateState.tapThreshold - 2,
                lastCompletedDayKey: nil
            )
        )
        let adService = InterstitialAdServiceStub()
        let sut = DailyInterstitialGateViewModel(stateStore: store, adService: adService)

        sut.prepareIfNeeded(canShowPersonalizedAds: true)
        sut.prepareIfNeeded(canShowPersonalizedAds: true)

        XCTAssertEqual(adService.prepareCalls.count, 1)
    }

    func test_recordScreenTap_showsGateWhenThresholdReachedAndReady() {
        let store = DailyInterstitialGateStoreStub(
            state: DailyInterstitialGateState(
                dayKey: "2026-03-15",
                tapCount: DailyInterstitialGateState.tapThreshold - 1,
                lastCompletedDayKey: nil
            )
        )
        let adService = InterstitialAdServiceStub()
        let sut = DailyInterstitialGateViewModel(stateStore: store, adService: adService)
        adService.sendState(isReady: true, isLoading: false, errorMessage: nil)

        sut.recordScreenTap()

        XCTAssertTrue(sut.isGatePresented)
        XCTAssertEqual(adService.presentIfReadyCallCount, 0)
    }

    func test_applyAdState_showsGateAfterThresholdWasReached() {
        let store = DailyInterstitialGateStoreStub(
            state: DailyInterstitialGateState(
                dayKey: "2026-03-15",
                tapCount: DailyInterstitialGateState.tapThreshold,
                lastCompletedDayKey: nil
            )
        )
        let adService = InterstitialAdServiceStub()
        let sut = DailyInterstitialGateViewModel(stateStore: store, adService: adService)

        adService.sendState(isReady: true, isLoading: false, errorMessage: nil)

        XCTAssertTrue(sut.isGatePresented)
        XCTAssertEqual(adService.presentIfReadyCallCount, 0)
    }

    func test_gatePresentation_tracksAdDialogShownWhenGateBecomesVisible() {
        let store = DailyInterstitialGateStoreStub(
            state: DailyInterstitialGateState(
                dayKey: "2026-03-15",
                tapCount: DailyInterstitialGateState.tapThreshold,
                lastCompletedDayKey: nil
            )
        )
        let adService = InterstitialAdServiceStub()
        let analytics = AnalyticsTrackerStub()
        let sut = DailyInterstitialGateViewModel(
            stateStore: store,
            adService: adService,
            analytics: analytics
        )

        adService.sendState(isReady: true, isLoading: false, errorMessage: nil)

        XCTAssertTrue(sut.isGatePresented)
        XCTAssertEqual(analytics.adDialogShownCount, 1)
    }
}

@MainActor
private final class DailyInterstitialGateStoreStub: DailyInterstitialGateStoring {
    var state: DailyInterstitialGateState

    init(state: DailyInterstitialGateState) {
        self.state = state
    }

    func currentState() -> DailyInterstitialGateState {
        state
    }

    func recordTap() -> DailyInterstitialGateState {
        guard !state.hasCompletedToday, !state.hasReachedThreshold else {
            return state
        }

        state.tapCount += 1
        return state
    }

    func markCompleted() -> DailyInterstitialGateState {
        state.lastCompletedDayKey = state.dayKey
        return state
    }
}

@MainActor
private final class InterstitialAdServiceStub: InterstitialAdServing {
    var onStateChange: ((AdMobInterstitialService.State) -> Void)?
    var onAdFinished: ((Bool) -> Void)?
    var prepareCalls: [Bool] = []
    var presentIfReadyCallCount = 0
    var presentIfReadyResult = true

    func prepare(canShowPersonalizedAds: Bool) {
        prepareCalls.append(canShowPersonalizedAds)
    }

    func presentIfReady() -> Bool {
        presentIfReadyCallCount += 1
        return presentIfReadyResult
    }

    func sendState(isReady: Bool, isLoading: Bool, errorMessage: String?) {
        onStateChange?(
            AdMobInterstitialService.State(
                isReady: isReady,
                isLoading: isLoading,
                errorMessage: errorMessage
            )
        )
    }
}

@MainActor
private final class AnalyticsTrackerStub: AnalyticsTracking {
    private(set) var appOpenedCount = 0
    private(set) var adDialogShownCount = 0

    func trackAppOpened() {
        appOpenedCount += 1
    }

    func trackAdDialogShown() {
        adDialogShownCount += 1
    }
}
