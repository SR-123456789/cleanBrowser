import Foundation

@MainActor
final class DailyInterstitialGateViewModel: ObservableObject {
    @Published private(set) var isGatePresented = false
    @Published private(set) var isAdReady = false
    @Published private(set) var isLoadingAd = false
    @Published private(set) var isAdPresenting = false
    @Published private(set) var errorMessage: String?

    private let stateStore: any DailyInterstitialGateStoring
    private let adService: AdMobInterstitialService
    private var canShowPersonalizedAds = false
    private var hasReachedThresholdToday = false

    init() {
        self.stateStore = UserDefaultsDailyInterstitialGateStore()
        self.adService = AdMobInterstitialService()
        bindDependencies()
        sync(with: stateStore.currentState())
    }

    init(
        stateStore: any DailyInterstitialGateStoring,
        adService: AdMobInterstitialService
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
        isGatePresented
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

        guard !state.hasCompletedToday else {
            return
        }

        adService.prepare(canShowPersonalizedAds: canShowPersonalizedAds)
    }

    func recordScreenTap() {
        guard !isGatePresented else { return }

        let state = stateStore.recordTap()
        sync(with: state)

        if state.hasReachedThreshold {
            adService.prepare(canShowPersonalizedAds: canShowPersonalizedAds)
        }
    }

    func presentAd() {
        errorMessage = nil
        isAdPresenting = true

        guard adService.presentIfReady() else {
            isAdPresenting = false
            adService.prepare(canShowPersonalizedAds: canShowPersonalizedAds)
            if !isLoadingAd {
                errorMessage = "広告を準備しています。読み込み後にもう一度お試しください。"
            }
            return
        }
    }

    private func sync(with state: DailyInterstitialGateState) {
        hasReachedThresholdToday = state.hasReachedThreshold

        if state.hasCompletedToday {
            errorMessage = nil
        } else if !state.hasReachedThreshold {
            errorMessage = nil
        }

        updateGatePresentation()
    }

    private func applyAdState(_ state: AdMobInterstitialService.State) {
        isAdReady = state.isReady
        isLoadingAd = state.isLoading

        if let errorMessage = state.errorMessage, isGatePresented {
            self.errorMessage = errorMessage
        }

        updateGatePresentation()
    }

    private func handleAdFinished(_ didFinish: Bool) {
        isAdPresenting = false

        guard didFinish else {
            updateGatePresentation()
            return
        }

        let state = stateStore.markCompleted()
        sync(with: state)
        isAdReady = false
        isLoadingAd = false
        updateGatePresentation()
    }

    private func updateGatePresentation() {
        isGatePresented = hasReachedThresholdToday && isAdReady && !isAdPresenting
    }
}
