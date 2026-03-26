import Foundation

@MainActor
final class DailyInterstitialGateViewModel: ObservableObject {
    private static let adPreloadThreshold = max(1, DailyInterstitialGateState.tapThreshold - 2)

    @Published private(set) var isGatePresented = false
    @Published private(set) var isAdReady = false
    @Published private(set) var isLoadingAd = false
    @Published private(set) var isAdPresenting = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var isStartupVisible = true

    private let stateStore: any DailyInterstitialGateStoring
    private let adService: any InterstitialAdServing
    private let analytics: any AnalyticsTracking
    private let scheduleAdPresentation: (@escaping @Sendable () -> Void) -> Void
    private var canShowPersonalizedAds = false
    private var hasReachedThresholdToday = false
    private var hasCompletedToday = false
    private var lastPreparedDayKey: String?

    init(
        scheduleAdPresentation: @escaping (@escaping @Sendable () -> Void) -> Void = { work in
            DispatchQueue.main.async(execute: work)
        }
    ) {
        self.stateStore = UserDefaultsDailyInterstitialGateStore()
        self.adService = AdMobInterstitialService()
        self.analytics = NoopAnalyticsManager()
        self.scheduleAdPresentation = scheduleAdPresentation
        bindDependencies()
        sync(with: stateStore.currentState())
    }

    init(
        analytics: any AnalyticsTracking,
        scheduleAdPresentation: @escaping (@escaping @Sendable () -> Void) -> Void = { work in
            DispatchQueue.main.async(execute: work)
        }
    ) {
        self.stateStore = UserDefaultsDailyInterstitialGateStore()
        self.adService = AdMobInterstitialService()
        self.analytics = analytics
        self.scheduleAdPresentation = scheduleAdPresentation
        bindDependencies()
        sync(with: stateStore.currentState())
    }

    init(
        stateStore: any DailyInterstitialGateStoring,
        adService: any InterstitialAdServing,
        analytics: any AnalyticsTracking = NoopAnalyticsManager(),
        scheduleAdPresentation: @escaping (@escaping @Sendable () -> Void) -> Void = { work in
            DispatchQueue.main.async(execute: work)
        }
    ) {
        self.stateStore = stateStore
        self.adService = adService
        self.analytics = analytics
        self.scheduleAdPresentation = scheduleAdPresentation
        bindDependencies()
        sync(with: stateStore.currentState())
    }

    private func bindDependencies() {
        adService.onStateChange = { [weak self] state in
            self?.applyAdState(state)
        }
        adService.onAdFinished = { [weak self] result in
            self?.handleAdFinished(result)
        }
    }

    var isBlockingUI: Bool {
        false
    }

    var shouldTrackScreenTaps: Bool {
        isStartupVisible && !hasReachedThresholdToday && !hasCompletedToday && !isAdPresenting
    }

    var titleText: String {
        "1日1回の広告表示"
    }

    var descriptionText: String {
        "無料で使い続けられるよう、1日1回だけ広告の表示をお願いしています。広告の表示を開始すると、その日は再表示されません。"
    }

    var detailText: String {
        if let errorMessage {
            return errorMessage
        }

        if isLoadingAd && !isAdReady {
            return "広告を準備しています。読み込みが終わるとボタンを押せます。"
        }

        return "この案内は1日1回だけ表示されます。"
    }

    var primaryButtonTitle: String {
        "広告を表示する"
    }

    var isPrimaryButtonEnabled: Bool {
        !isLoadingAd
    }

    func prepareIfNeeded(canShowPersonalizedAds: Bool) {
        self.canShowPersonalizedAds = canShowPersonalizedAds

        let state = stateStore.currentState()
        sync(with: state)

        guard isStartupVisible else {
            return
        }

        guard shouldPrepareAd(for: state) else {
            return
        }

        requestAdIfNeeded(for: state)
    }

    func recordScreenTap() {
        guard shouldTrackScreenTaps else { return }

        let hadReachedThreshold = hasReachedThresholdToday
        let shouldPreloadBeforeTap = shouldPreloadAd
        let state = stateStore.recordTap()
        sync(with: state)

        if (state.hasReachedThreshold && !hadReachedThreshold)
            || (shouldPreloadAd && !shouldPreloadBeforeTap) {
            requestAdIfNeeded(for: state)
        }
    }

    func presentAd() {
        setErrorMessage(nil)
        setAdPresenting(true)
        let state = stateStore.markCompleted()
        sync(with: state)
        updateGatePresentation()

        scheduleAdPresentation { [weak self] in
            Task { @MainActor [weak self] in
                self?.performPresentAd()
            }
        }
    }

    private func performPresentAd() {
        guard adService.presentIfReady() else {
            setAdPresenting(false)
            updateGatePresentation()
            requestAdIfNeeded(for: stateStore.currentState(), force: true)
            if !isLoadingAd {
                setErrorMessage("広告を準備しています。読み込み後にもう一度お試しください。")
            }
            return
        }
    }

    func setStartupVisibility(_ isVisible: Bool) {
        guard isStartupVisible != isVisible else { return }
        isStartupVisible = isVisible

        if !isVisible {
            setErrorMessage(nil)
        }

        updateGatePresentation()
    }

    private func sync(with state: DailyInterstitialGateState) {
        hasReachedThresholdToday = state.hasReachedThreshold
        hasCompletedToday = state.hasCompletedToday
        if lastPreparedDayKey != state.dayKey, !state.hasCompletedToday {
            lastPreparedDayKey = nil
        }

        if state.hasCompletedToday {
            setErrorMessage(nil)
        } else if !state.hasReachedThreshold {
            setErrorMessage(nil)
        }

        updateGatePresentation()
    }

    private func applyAdState(_ state: AdMobInterstitialService.State) {
        setAdReady(state.isReady)
        setLoadingAd(state.isLoading)

        if let errorMessage = state.errorMessage, isGatePresented {
            setErrorMessage(errorMessage)
        }

        updateGatePresentation()
    }

    private func handleAdFinished(_ result: InterstitialAdFinishResult) {
        setAdPresenting(false)
        updateGatePresentation()

        setAdReady(false)
        setLoadingAd(false)

        if result == .dismissedLikelyByClose {
            analytics.trackAdDialogViewed()
        }

        updateGatePresentation()
    }

    private func updateGatePresentation() {
        let newValue = isStartupVisible && hasReachedThresholdToday && isAdReady && !isAdPresenting
        guard isGatePresented != newValue else { return }
        isGatePresented = newValue
        if newValue {
            analytics.trackAdDialogShown()
        }
    }

    private var shouldPreloadAd: Bool {
        hasReachedThresholdToday || stateStore.currentState().tapCount >= Self.adPreloadThreshold
    }

    private func shouldPrepareAd(for state: DailyInterstitialGateState) -> Bool {
        guard !state.hasCompletedToday else { return false }
        return state.tapCount >= Self.adPreloadThreshold
    }

    private func requestAdIfNeeded(for state: DailyInterstitialGateState, force: Bool = false) {
        guard shouldPrepareAd(for: state) else { return }
        guard force || lastPreparedDayKey != state.dayKey else { return }

        lastPreparedDayKey = state.dayKey
        adService.prepare(canShowPersonalizedAds: canShowPersonalizedAds)
    }

    private func setAdReady(_ value: Bool) {
        guard isAdReady != value else { return }
        isAdReady = value
    }

    private func setLoadingAd(_ value: Bool) {
        guard isLoadingAd != value else { return }
        isLoadingAd = value
    }

    private func setAdPresenting(_ value: Bool) {
        guard isAdPresenting != value else { return }
        isAdPresenting = value
    }

    private func setErrorMessage(_ value: String?) {
        guard errorMessage != value else { return }
        errorMessage = value
    }
}
