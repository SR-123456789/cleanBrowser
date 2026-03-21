import SwiftUI
import WebKit

enum BrowserTabCreationSource: Equatable {
    case manual
    case pageOpened
    case userOpened
}

@MainActor
final class BrowserTab: ObservableObject, Identifiable {
    let id = UUID()
    let openerTabID: UUID?
    let creationSource: BrowserTabCreationSource
    @Published var webView: WKWebView?
    @Published var title: String {
        didSet {
            guard title != oldValue else { return }
            onPersistableStateChange?()
        }
    }
    @Published var url: String {
        didSet {
            guard url != oldValue else { return }
            onPersistableStateChange?()
        }
    }
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isLoading: Bool = false
    @Published var isMuted: Bool = false
    var onPersistableStateChange: (() -> Void)?

    init(
        url: String = BrowserURLResolver.defaultHomePage,
        title: String = "新しいタブ",
        openerTabID: UUID? = nil,
        creationSource: BrowserTabCreationSource = .manual
    ) {
        self.url = url
        self.title = title
        self.openerTabID = openerTabID
        self.creationSource = creationSource
    }

    func setWebViewIfNeeded(_ webView: WKWebView?) {
        guard self.webView !== webView else { return }
        self.webView = webView
    }

    func setTitleIfNeeded(_ title: String) {
        guard self.title != title else { return }
        self.title = title
    }

    func setURLIfNeeded(_ url: String) {
        guard self.url != url else { return }
        self.url = url
    }

    func setNavigationStateIfNeeded(
        canGoBack: Bool,
        canGoForward: Bool,
        isLoading: Bool
    ) {
        if self.canGoBack != canGoBack {
            self.canGoBack = canGoBack
        }
        if self.canGoForward != canGoForward {
            self.canGoForward = canGoForward
        }
        if self.isLoading != isLoading {
            self.isLoading = isLoading
        }
    }

    func setMutedIfNeeded(_ isMuted: Bool) {
        guard self.isMuted != isMuted else { return }
        self.isMuted = isMuted
    }

    func teardownWebView() {
        guard let webView else { return }
        let userContentController = webView.configuration.userContentController
        userContentController.removeScriptMessageHandler(forName: "inputFocused")
        userContentController.removeScriptMessageHandler(forName: "inputBlurred")
        userContentController.removeScriptMessageHandler(forName: "inputGuideRequested")
        userContentController.removeScriptMessageHandler(forName: "confirmNav")
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        webView.stopLoading()
        onPersistableStateChange = nil
        setWebViewIfNeeded(nil)
    }
}
