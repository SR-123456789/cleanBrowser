import SwiftUI

struct StartupUpdatePrompt: Equatable, Identifiable {
    let title: String
    let message: String
    let updateURL: URL?
    let isMandatory: Bool

    var id: String {
        [
            isMandatory ? "mandatory" : "optional",
            title,
            message,
            updateURL?.absoluteString ?? ""
        ].joined(separator: "::")
    }
}

@MainActor
final class ContentViewModel: ObservableObject {
    @Published var isUnlocked = false
    @Published var pinInput = ""
    @Published var errorMessage: String?
    @Published var showPINSettings = false
    @Published var hasPINBeenSet = false
    @Published var isPrivacyShieldVisible = false
    @Published private(set) var startupUpdatePrompt: StartupUpdatePrompt?

    private let pinService: any PINManaging
    private let startupLoader: any StartupLoading
    private let startupAdVisibilityController: any StartupAdVisibilityControlling
    private let updatePromptHistoryStore: any StartupUpdatePromptHistoryStoring
    private let appVersionProvider: () -> String
    private var shouldLockOnNextActive = false
    private var pendingInactiveShieldWorkItem: DispatchWorkItem?
    private let inactiveShieldDelay: TimeInterval
    private let scheduleDelayedWork: (TimeInterval, DispatchWorkItem) -> Void
    private var hasLoadedStartup = false
    private var isLoadingStartup = false

    init(
        pinService: any PINManaging,
        startupLoader: any StartupLoading = StartupAPIClient(),
        startupAdVisibilityController: any StartupAdVisibilityControlling,
        updatePromptHistoryStore: any StartupUpdatePromptHistoryStoring = UserDefaultsStartupUpdatePromptHistoryStore(),
        appVersionProvider: @escaping () -> String = { Bundle.main.cleanBrowserAppVersion },
        inactiveShieldDelay: TimeInterval = 0.35,
        scheduleDelayedWork: @escaping (TimeInterval, DispatchWorkItem) -> Void = { delay, workItem in
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    ) {
        self.pinService = pinService
        self.startupLoader = startupLoader
        self.startupAdVisibilityController = startupAdVisibilityController
        self.updatePromptHistoryStore = updatePromptHistoryStore
        self.appVersionProvider = appVersionProvider
        self.inactiveShieldDelay = inactiveShieldDelay
        self.scheduleDelayedWork = scheduleDelayedWork
    }

    var shouldShowInitialSetup: Bool {
        (pinService.isFirstLaunch || !pinService.hasPINSet) && !hasPINBeenSet
    }

    func verifyPIN(_ pin: String) {
        if pinService.verifyPIN(pin) {
            withAnimation {
                isUnlocked = true
            }
            errorMessage = nil
        } else {
            errorMessage = "PINが間違えています"
            pinInput = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.errorMessage = nil
            }
        }
    }

    func resetToPIN() {
        isUnlocked = false
        pinInput = ""
        errorMessage = nil
    }

    func onPINSet() {
        hasPINBeenSet = true
    }

    func appendDigit(_ digit: String) {
        guard pinInput.count < 4 else { return }
        pinInput.append(digit)
        if pinInput.count == 4 {
            verifyPIN(pinInput)
        }
    }

    func deleteLastDigit() {
        guard !pinInput.isEmpty else { return }
        pinInput.removeLast()
    }

    func handleScenePhase(_ scenePhase: ScenePhase) {
        switch scenePhase {
        case .active:
            cancelPendingInactiveShield()
            isPrivacyShieldVisible = false
            if shouldLockOnNextActive && pinService.hasPINSet {
                resetToPIN()
            }
            shouldLockOnNextActive = false
        case .background:
            cancelPendingInactiveShield()
            isPrivacyShieldVisible = true
            shouldLockOnNextActive = true
        case .inactive:
            scheduleInactiveShield()
        @unknown default:
            break
        }
    }

    func loadStartupIfNeeded() {
        guard !hasLoadedStartup, !isLoadingStartup else { return }
        isLoadingStartup = true

        let appVersion = appVersionProvider()

        Task { [weak self] in
            guard let self else { return }

            do {
                let response = try await startupLoader.fetchStartup(appVersion: appVersion)
                applyStartupResponse(response, appVersion: appVersion)
                hasLoadedStartup = true
            } catch {
                startupAdVisibilityController.isDailyInterstitialVisible = false
                logStartupLoadFailure(error)
                startupUpdatePrompt = nil
            }

            isLoadingStartup = false
        }
    }

    func dismissStartupUpdatePrompt() {
        guard startupUpdatePrompt?.isMandatory == false else { return }
        startupUpdatePrompt = nil
    }

    private func scheduleInactiveShield() {
        cancelPendingInactiveShield()

        let workItem = DispatchWorkItem { [weak self] in
            self?.isPrivacyShieldVisible = true
        }

        pendingInactiveShieldWorkItem = workItem
        scheduleDelayedWork(inactiveShieldDelay, workItem)
    }

    private func cancelPendingInactiveShield() {
        pendingInactiveShieldWorkItem?.cancel()
        pendingInactiveShieldWorkItem = nil
    }

    private func applyStartupResponse(_ response: StartupResponse, appVersion: String) {
        let isDailyInterstitialVisible = response.ads.first(where: { $0.adID == "daily_interstitial" })?.isShow ?? false
        startupAdVisibilityController.isDailyInterstitialVisible = isDailyInterstitialVisible

        startupUpdatePrompt = makeStartupUpdatePrompt(
            from: response.update,
            appVersion: appVersion
        )
    }

    private func makeStartupUpdatePrompt(
        from update: StartupUpdateResponse,
        appVersion: String
    ) -> StartupUpdatePrompt? {
        let title = update.mustUpdate ? "アップデートが必要です" : "アップデートしてください"
        let updateURL = URL(string: update.updateLink)

        if update.mustUpdate {
            return StartupUpdatePrompt(
                title: title,
                message: update.message,
                updateURL: updateURL,
                isMandatory: true
            )
        }

        guard update.shouldUpdate else {
            return nil
        }

        if !update.repeatUpdatePrompt {
            guard !updatePromptHistoryStore.hasShownPrompt(appVersion: appVersion, message: update.message) else {
                return nil
            }

            updatePromptHistoryStore.markPromptShown(appVersion: appVersion, message: update.message)
        }

        return StartupUpdatePrompt(
            title: title,
            message: update.message,
            updateURL: updateURL,
            isMandatory: false
        )
    }

    private func logStartupLoadFailure(_ error: Error) {
#if DEBUG
        print("Startup API load failed:", error)
#endif
    }
}
