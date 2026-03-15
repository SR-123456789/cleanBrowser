import Foundation
import GoogleMobileAds

@MainActor
protocol InterstitialAdServing: AnyObject {
    var onStateChange: ((AdMobInterstitialService.State) -> Void)? { get set }
    var onAdFinished: ((Bool) -> Void)? { get set }

    func prepare(canShowPersonalizedAds: Bool)
    @discardableResult
    func presentIfReady() -> Bool
}

@MainActor
final class AdMobInterstitialService: NSObject, InterstitialAdServing {
    struct State: Equatable {
        var isReady = false
        var isLoading = false
        var errorMessage: String?
    }

    var onStateChange: ((State) -> Void)?
    var onAdFinished: ((Bool) -> Void)?

    private var interstitialAd: InterstitialAd?
    private var state = State() {
        didSet {
            onStateChange?(state)
        }
    }
    private var lastCanShowPersonalizedAds = false
    private var didStartSDK = false

    func prepare(canShowPersonalizedAds: Bool) {
        startSDKIfNeeded()
        lastCanShowPersonalizedAds = canShowPersonalizedAds

        guard interstitialAd == nil, !state.isLoading else {
            return
        }

        let request = Request()
        if !canShowPersonalizedAds {
            let extras = Extras()
            extras.additionalParameters = ["npa": "1"]
            request.register(extras)
        }

        updateState(isReady: false, isLoading: true, errorMessage: nil)

        InterstitialAd.load(with: AdsConfiguration.interstitialUnitID, request: request) { [weak self] ad, error in
            guard let self else { return }

            if let error {
                self.interstitialAd = nil
                self.updateState(
                    isReady: false,
                    isLoading: false,
                    errorMessage: error.localizedDescription
                )
                return
            }

            self.interstitialAd = ad
            self.interstitialAd?.fullScreenContentDelegate = self
            self.updateState(isReady: ad != nil, isLoading: false, errorMessage: nil)
        }
    }

    @discardableResult
    func presentIfReady() -> Bool {
        guard let interstitialAd else {
            return false
        }

        guard let rootViewController = ViewControllerLocator.topViewController() else {
            updateState(
                isReady: false,
                isLoading: false,
                errorMessage: "広告の表示先を準備できませんでした。"
            )
            self.interstitialAd = nil
            return false
        }

        do {
            try interstitialAd.canPresent(from: rootViewController)
            interstitialAd.present(from: rootViewController)
            return true
        } catch {
            self.interstitialAd = nil
            updateState(
                isReady: false,
                isLoading: false,
                errorMessage: "広告を表示できませんでした。もう一度お試しください。"
            )
            prepare(canShowPersonalizedAds: lastCanShowPersonalizedAds)
            return false
        }
    }

    private func startSDKIfNeeded() {
        guard !didStartSDK else { return }
        didStartSDK = true
        MobileAds.shared.start(completionHandler: nil)
    }

    private func updateState(isReady: Bool, isLoading: Bool, errorMessage: String?) {
        let newState = State(isReady: isReady, isLoading: isLoading, errorMessage: errorMessage)
        guard state != newState else { return }
        state = newState
    }
}

extension AdMobInterstitialService: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        interstitialAd = nil
        updateState(isReady: false, isLoading: false, errorMessage: nil)
        onAdFinished?(true)
    }

    func ad(
        _ ad: any FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        interstitialAd = nil
        updateState(
            isReady: false,
            isLoading: false,
            errorMessage: "広告を表示できませんでした。通信状況をご確認のうえ、もう一度お試しください。"
        )
        onAdFinished?(false)
        prepare(canShowPersonalizedAds: lastCanShowPersonalizedAds)
    }
}
