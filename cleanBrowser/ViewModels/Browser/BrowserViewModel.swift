import Combine
import Foundation
import SwiftUI

@MainActor
final class BrowserViewModel: ObservableObject {
    @Published var isKeyboardVisible = false
    @Published var showPINSettings = false
    @Published var showSettingsSheet = false
    @Published var showTabOverview = false

    let browserStore: BrowserStore

    private var cancellables = Set<AnyCancellable>()

    init(browserStore: BrowserStore) {
        self.browserStore = browserStore

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
                if !isEnabled {
                    self?.isKeyboardVisible = false
                }
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

    func setKeyboardVisible(_ isVisible: Bool) {
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
}
