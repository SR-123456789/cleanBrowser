import Combine
import Foundation
import SwiftUI

@MainActor
final class BrowserViewModel: ObservableObject {
    @Published var isKeyboardVisible = false
    @Published var showCustomKeyboardGuide = false
    @Published var showPINSettings = false
    @Published var showSettingsSheet = false
    @Published var showTabOverview = false

    let browserStore: BrowserStore

    private let analytics: any AnalyticsTracking
    private var cancellables = Set<AnyCancellable>()
    private var isSystemKeyboardSessionActive = false
    private var isCustomKeyboardGuidePending = false

    init(
        browserStore: BrowserStore,
        analytics: any AnalyticsTracking = NoopAnalyticsManager()
    ) {
        self.browserStore = browserStore
        self.analytics = analytics

        browserStore.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        browserStore.$customKeyboardEnabled
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in
                guard let self else { return }
                if !isEnabled {
                    self.isKeyboardVisible = false
                    return
                }

                self.showCustomKeyboardGuide = false
                self.isCustomKeyboardGuidePending = false
            }
            .store(in: &cancellables)
    }

    var activeTab: BrowserTab? {
        browserStore.activeTab
    }

    var tabCount: Int {
        browserStore.tabs.count
    }

    var navigationTitle: String {
        activeTab?.title ?? "Clean Browser"
    }

    var shouldShowCustomKeyboard: Bool {
        isKeyboardVisible && browserStore.customKeyboardEnabled
    }

    var isMutedGlobal: Bool {
        browserStore.isMutedGlobal
    }

    var isModalPresented: Bool {
        showPINSettings || showSettingsSheet || showTabOverview
    }

    func handleWebInputStateChange(_ change: WebInputStateChange) {
        if change.usesCustomKeyboard {
            isSystemKeyboardSessionActive = false
            setCustomKeyboardVisible(change.isFocused)
            return
        }

        isKeyboardVisible = false

        if change.isFocused {
            if !isSystemKeyboardSessionActive {
                browserStore.recordSystemKeyboardUse()
                isSystemKeyboardSessionActive = true
            }
            return
        }

        isSystemKeyboardSessionActive = false
    }

    func handleSystemKeyboardGuideRequested() {
        guard browserStore.shouldSuggestCustomKeyboardGuide else { return }
        isSystemKeyboardSessionActive = false
        isCustomKeyboardGuidePending = true
        presentCustomKeyboardGuideIfPossible()
    }

    func handleModalPresentationChanged() {
        presentCustomKeyboardGuideIfPossible()
    }

    func dismissCustomKeyboardGuide() {
        analytics.trackKeyboardChoiceSelected(.system)
        browserStore.finishCustomKeyboardGuidePresentation()
        isCustomKeyboardGuidePending = false
        withAnimation(.easeInOut(duration: 0.2)) {
            showCustomKeyboardGuide = false
        }
        activeTab?.webView?.evaluateJavaScript(WebViewJS.focusLastEditableElementScript, completionHandler: nil)
    }

    func enableCustomKeyboardFromGuide() {
        analytics.trackKeyboardChoiceSelected(.custom)
        browserStore.finishCustomKeyboardGuidePresentation()
        browserStore.enableCustomKeyboard()
        isCustomKeyboardGuidePending = false
        withAnimation(.easeInOut(duration: 0.2)) {
            showCustomKeyboardGuide = false
        }
        activeTab?.webView?.evaluateJavaScript(WebViewJS.activateCustomKeyboardScript, completionHandler: nil)
    }

    private func setCustomKeyboardVisible(_ isVisible: Bool) {
        guard browserStore.customKeyboardEnabled else {
            isKeyboardVisible = false
            return
        }

        isKeyboardVisible = isVisible
    }

    func toggleKeyboard() {
        guard browserStore.customKeyboardEnabled else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            isKeyboardVisible.toggle()
        }
    }

    func dismissCustomKeyboard() {
        guard isKeyboardVisible else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            isKeyboardVisible = false
        }
    }

    func switchToSystemKeyboard() {
        dismissCustomKeyboard()
        browserStore.customKeyboardEnabled = false
        activeTab?.webView?.evaluateJavaScript(WebViewJS.restoreNativeKeyboardScript, completionHandler: nil)
    }

    func handleInterstitialPresentationChanged(_ isPresenting: Bool) {
        if isPresenting {
            dismissCustomKeyboard()
        }

        browserStore.setWebViewsSuspendedForInterstitial(isPresenting)
    }

    func beginAddressEditing() {
        isKeyboardVisible = false
        activeTab?.webView?.evaluateJavaScript(WebViewJS.blurActiveElementScript, completionHandler: nil)
    }

    func navigate(to rawInput: String) {
        guard let activeTab, let destinationURL = BrowserURLResolver.resolve(rawInput) else { return }
        activeTab.setURLIfNeeded(destinationURL.absoluteString)
        activeTab.webView?.load(URLRequest(url: destinationURL))
    }

    func goBack() {
        activeTab?.webView?.goBack()
    }

    func goForward() {
        activeTab?.webView?.goForward()
    }

    func toggleMute() {
        browserStore.toggleGlobalMute()
    }

    private func presentCustomKeyboardGuideIfPossible() {
        guard isCustomKeyboardGuidePending,
              !showCustomKeyboardGuide,
              !isModalPresented,
              browserStore.shouldSuggestCustomKeyboardGuide
        else {
            return
        }

        browserStore.beginCustomKeyboardGuidePresentation()
        analytics.trackKeyboardChoiceDialogShown()
        withAnimation(.spring(response: 0.36, dampingFraction: 0.9)) {
            showCustomKeyboardGuide = true
        }
        isCustomKeyboardGuidePending = false
    }
}
