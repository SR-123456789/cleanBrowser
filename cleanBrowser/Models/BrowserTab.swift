import SwiftUI
import WebKit

@MainActor
final class BrowserTab: ObservableObject, Identifiable {
    let id = UUID()
    @Published var webView: WKWebView?
    @Published var title: String
    @Published var url: String
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isLoading: Bool = false
    @Published var isMuted: Bool = false

    init(url: String = BrowserURLResolver.defaultHomePage, title: String = "新しいタブ") {
        self.url = url
        self.title = title
    }

    func teardownWebView() {
        guard let webView else { return }
        let userContentController = webView.configuration.userContentController
        userContentController.removeScriptMessageHandler(forName: "inputFocused")
        userContentController.removeScriptMessageHandler(forName: "inputBlurred")
        userContentController.removeScriptMessageHandler(forName: "confirmNav")
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        webView.stopLoading()
        self.webView = nil
    }
}
