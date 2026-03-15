import Foundation

@MainActor
final class DailyInterstitialGateViewModel: ObservableObject {
    private static let adPreloadThreshold = max(1, DailyInterstitialGateState.tapThreshold - 2)

    @Published private(set) var isGatePresented = false
    @Published private(set) var isAdReady = false
    @Published private(set) var isLoadingAd = false
    @Published private(set) var isAdPresenting = false
    @Published private(set) var errorMessage: String?

    private let stateStore: any DailyInterstitialGateStoring
    private let adService: any InterstitialAdServing
    private var canShowPersonalizedAds = false
    private var hasReachedThresholdToday = false
    private var lastPreparedDayKey: String?

    init() {
        self.stateStore = UserDefaultsDailyInterstitialGateStore()
        self.adService = AdMobInterstitialService()
        bindDependencies()
        sync(with: stateStore.currentState())
    }

    init(
        stateStore: any DailyInterstitialGateStoring,
        adService: any InterstitialAdServing
    ) {
        self.stateStore = stateStore
        self.adService = adService
        bindDependencies()
        sync(with: stateStore.currentState())
    }

    private func bindDependencies() {
        adService.onStateChange = { [weak self] state in
            self?.applyAdState(state)
        }
        adService.onAdFinished = { [weak self] didFinish in
            self?.handleAdFinished(didFinish)
        }
    }

    var isBlockingUI: Bool {
        false
    }

    var shouldTrackScreenTaps: Bool {
        !hasReachedThresholdToday && !isAdPresenting
    }

    var titleText: String {
        "1日1回の広告表示"
    }

    var descriptionText: String {
        "無料で使い続けられるよう、1日1回だけ広告の表示をお願いしています。広告の表示が終わると、その日は再表示されません。"
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
        updateGatePresentation()

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

    private func sync(with state: DailyInterstitialGateState) {
        hasReachedThresholdToday = state.hasReachedThreshold
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

    private func handleAdFinished(_ didFinish: Bool) {
        setAdPresenting(false)
        updateGatePresentation()

        guard didFinish else {
            updateGatePresentation()
            return
        }

        let state = stateStore.markCompleted()
        sync(with: state)
        setAdReady(false)
        setLoadingAd(false)
        updateGatePresentation()
    }

    private func updateGatePresentation() {
        let newValue = hasReachedThresholdToday && isAdReady && !isAdPresenting
        guard isGatePresented != newValue else { return }
        isGatePresented = newValue
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
