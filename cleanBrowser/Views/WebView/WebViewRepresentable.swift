import SwiftUI
import UIKit
@preconcurrency import WebKit

struct WebViewRepresentable: UIViewRepresentable {
    @ObservedObject var tab: BrowserTab
    let browserStore: BrowserStore
    let onInputStateChanged: (WebInputStateChange) -> Void
    let onSystemKeyboardGuideRequested: () -> Void
    let confirmationPresenter: any NavigationConfirmationPresenting

    init(
        tab: BrowserTab,
        browserStore: BrowserStore,
        onInputStateChanged: @escaping (WebInputStateChange) -> Void,
        onSystemKeyboardGuideRequested: @escaping () -> Void,
        confirmationPresenter: any NavigationConfirmationPresenting = SystemNavigationConfirmationPresenter()
    ) {
        self.tab = tab
        self.browserStore = browserStore
        self.onInputStateChanged = onInputStateChanged
        self.onSystemKeyboardGuideRequested = onSystemKeyboardGuideRequested
        self.confirmationPresenter = confirmationPresenter
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            tab: tab,
            browserStore: browserStore,
            confirmationPresenter: confirmationPresenter,
            onInputStateChanged: onInputStateChanged,
            onSystemKeyboardGuideRequested: onSystemKeyboardGuideRequested
        )
    }

    func makeUIView(context: Context) -> WKWebView {
        if let existingWebView = tab.webView {
            context.coordinator.attach(to: existingWebView)
            if existingWebView.url == nil, let url = URL(string: tab.url) {
                existingWebView.load(URLRequest(url: url))
            }
            context.coordinator.applyRuntimePreferencesIfNeeded(to: existingWebView, force: true)
            return existingWebView
        }

        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)

        webView.scrollView.keyboardDismissMode = .onDrag
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.isScrollEnabled = true
        #if DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif

        let inputHandlerScript = WKUserScript(
            source: WebViewJS.inputHandlerScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        webView.configuration.userContentController.addUserScript(inputHandlerScript)

        let navigationGuardScript = WKUserScript(
            source: WebViewJS.navigationGuardScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        webView.configuration.userContentController.addUserScript(navigationGuardScript)

        context.coordinator.attach(to: webView)

        if let url = URL(string: tab.url) {
            webView.load(URLRequest(url: url))
        }

        tab.setWebViewIfNeeded(webView)
        context.coordinator.applyRuntimePreferencesIfNeeded(to: webView, force: true)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.updateDependencies(
            tab: tab,
            browserStore: browserStore,
            onInputStateChanged: onInputStateChanged,
            onSystemKeyboardGuideRequested: onSystemKeyboardGuideRequested
        )
        context.coordinator.applyRuntimePreferencesIfNeeded(to: uiView)
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        coordinator.detach(from: uiView)
        uiView.stopLoading()
    }

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
        private var tab: BrowserTab
        private var browserStore: BrowserStore
        private let confirmationPresenter: any NavigationConfirmationPresenting
        private var onInputStateChanged: (WebInputStateChange) -> Void
        private var onSystemKeyboardGuideRequested: () -> Void
        private var bypassNextDecision = false
        private var approvedURLFromJS: URL?
        private var lastAppliedPreferenceState: RuntimePreferenceState?

        init(
            tab: BrowserTab,
            browserStore: BrowserStore,
            confirmationPresenter: any NavigationConfirmationPresenting,
            onInputStateChanged: @escaping (WebInputStateChange) -> Void,
            onSystemKeyboardGuideRequested: @escaping () -> Void
        ) {
            self.tab = tab
            self.browserStore = browserStore
            self.confirmationPresenter = confirmationPresenter
            self.onInputStateChanged = onInputStateChanged
            self.onSystemKeyboardGuideRequested = onSystemKeyboardGuideRequested
        }

        func updateDependencies(
            tab: BrowserTab,
            browserStore: BrowserStore,
            onInputStateChanged: @escaping (WebInputStateChange) -> Void,
            onSystemKeyboardGuideRequested: @escaping () -> Void
        ) {
            self.tab = tab
            self.browserStore = browserStore
            self.onInputStateChanged = onInputStateChanged
            self.onSystemKeyboardGuideRequested = onSystemKeyboardGuideRequested
        }

        func attach(to webView: WKWebView) {
            webView.navigationDelegate = self
            webView.uiDelegate = self
            let userContentController = webView.configuration.userContentController
            userContentController.removeScriptMessageHandler(forName: "inputFocused")
            userContentController.removeScriptMessageHandler(forName: "inputBlurred")
            userContentController.removeScriptMessageHandler(forName: "inputGuideRequested")
            userContentController.removeScriptMessageHandler(forName: "confirmNav")
            userContentController.add(self, name: "inputFocused")
            userContentController.add(self, name: "inputBlurred")
            userContentController.add(self, name: "inputGuideRequested")
            userContentController.add(self, name: "confirmNav")
        }

        func applyRuntimePreferencesIfNeeded(to webView: WKWebView, force: Bool = false) {
            let currentState = RuntimePreferenceState(
                isMutedGlobal: browserStore.isMutedGlobal,
                confirmNavigation: browserStore.confirmNavigation,
                customKeyboardEnabled: browserStore.customKeyboardEnabled,
                shouldInterceptSystemKeyboardForGuide: browserStore.shouldSuggestCustomKeyboardGuide
            )

            guard force || lastAppliedPreferenceState != currentState else {
                return
            }

            lastAppliedPreferenceState = currentState
            browserStore.applyRuntimePreferences(to: webView)
        }

        func detach(from webView: WKWebView) {
            let userContentController = webView.configuration.userContentController
            userContentController.removeScriptMessageHandler(forName: "inputFocused")
            userContentController.removeScriptMessageHandler(forName: "inputBlurred")
            userContentController.removeScriptMessageHandler(forName: "inputGuideRequested")
            userContentController.removeScriptMessageHandler(forName: "confirmNav")
            webView.navigationDelegate = nil
            webView.uiDelegate = nil
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            DispatchQueue.main.async {
                let usesCustomKeyboard = self.usesCustomKeyboard(from: message)
                switch message.name {
                case "inputFocused":
                    self.onInputStateChanged(.init(isFocused: true, usesCustomKeyboard: usesCustomKeyboard))
                case "inputBlurred":
                    self.onInputStateChanged(.init(isFocused: false, usesCustomKeyboard: usesCustomKeyboard))
                case "inputGuideRequested":
                    self.onSystemKeyboardGuideRequested()
                case "confirmNav":
                    self.handleJavaScriptNavigationConfirmation(message)
                default:
                    break
                }
            }
        }

        private func usesCustomKeyboard(from message: WKScriptMessage) -> Bool {
            guard let body = message.body as? [String: Any],
                  let usesCustomKeyboard = body["usesCustomKeyboard"] as? Bool
            else {
                return browserStore.customKeyboardEnabled
            }

            return usesCustomKeyboard
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if bypassNextDecision {
                bypassNextDecision = false
                decisionHandler(.allow)
                return
            }

            guard browserStore.confirmNavigation else {
                decisionHandler(.allow)
                return
            }

            let isMainFrame = navigationAction.targetFrame?.isMainFrame ?? true
            guard isMainFrame else {
                decisionHandler(.allow)
                return
            }

            guard let requestURL = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            let scheme = (requestURL.scheme ?? "").lowercased()
            guard scheme == "http" || scheme == "https" else {
                decisionHandler(.allow)
                return
            }

            if isSameDocumentNavigation(current: webView.url, target: requestURL) {
                decisionHandler(.allow)
                return
            }

            if let approvedURL = approvedURLFromJS, matchesApprovedURL(approvedURL, requestURL: requestURL) {
                approvedURLFromJS = nil
                decisionHandler(.allow)
                return
            }

            let sourceHost = webView.url?.host
            if !browserStore.shouldConfirmNavigation(current: webView.url, target: requestURL, sourceHost: sourceHost) {
                decisionHandler(.allow)
                return
            }

            DispatchQueue.main.async {
                self.confirmationPresenter.confirmNavigation(
                    to: requestURL.absoluteString,
                    onConfirm: {
                        self.bypassNextDecision = true
                        webView.load(navigationAction.request)
                        decisionHandler(.cancel)
                    },
                    onCancel: {
                        decisionHandler(.cancel)
                        self.handleCancelledExternalNavigation()
                    }
                )
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.tab.setNavigationStateIfNeeded(
                    canGoBack: self.tab.canGoBack,
                    canGoForward: self.tab.canGoForward,
                    isLoading: true
                )
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.tab.setNavigationStateIfNeeded(
                    canGoBack: webView.canGoBack,
                    canGoForward: webView.canGoForward,
                    isLoading: false
                )

                if let url = webView.url {
                    self.tab.setURLIfNeeded(url.absoluteString)
                }

                webView.evaluateJavaScript("document.title") { result, _ in
                    guard let title = result as? String, !title.isEmpty else { return }
                    DispatchQueue.main.async {
                        self.tab.setTitleIfNeeded(title)
                    }
                }

                self.applyRuntimePreferencesIfNeeded(to: webView, force: true)
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.tab.setNavigationStateIfNeeded(
                    canGoBack: self.tab.canGoBack,
                    canGoForward: self.tab.canGoForward,
                    isLoading: false
                )
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.tab.setNavigationStateIfNeeded(
                    canGoBack: self.tab.canGoBack,
                    canGoForward: self.tab.canGoForward,
                    isLoading: false
                )
            }
        }

        @available(iOS 13.0, *)
        func webView(
            _ webView: WKWebView,
            contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
            completionHandler: @escaping (UIContextMenuConfiguration?) -> Void
        ) {
            guard let linkURL = elementInfo.linkURL else {
                completionHandler(nil)
                return
            }

            let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
                let openLink = UIAction(
                    title: "リンクを開く",
                    image: UIImage(systemName: "safari")
                ) { _ in
                    webView.load(URLRequest(url: linkURL))
                }

                let openInNewTab = UIAction(
                    title: "別タブで開く",
                    image: UIImage(systemName: "plus.square.on.square")
                ) { [weak self] _ in
                    self?.browserStore.addNewTab(
                        url: linkURL.absoluteString,
                        openerTabID: self?.browserStore.activeTab?.id,
                        creationSource: .userOpened
                    )
                }

                let copyLink = UIAction(
                    title: "リンクをコピー",
                    image: UIImage(systemName: "doc.on.doc")
                ) { _ in
                    UIPasteboard.general.string = linkURL.absoluteString
                }

                return UIMenu(children: [openLink, openInNewTab, copyLink] + suggestedActions)
            }

            completionHandler(configuration)
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            guard navigationAction.targetFrame == nil,
                  let requestURL = navigationAction.request.url
            else {
                return nil
            }

            browserStore.addNewTab(
                url: requestURL.absoluteString,
                openerTabID: browserStore.activeTab?.id,
                creationSource: .pageOpened
            )
            return nil
        }

        private func handleJavaScriptNavigationConfirmation(_ message: WKScriptMessage) {
            guard browserStore.confirmNavigation else { return }
            guard let body = message.body as? [String: Any], let urlString = body["url"] as? String else { return }

            let sourceHost = body["from"] as? String
            let serializedBody = (try? JSONSerialization.data(withJSONObject: body))
                .flatMap { String(data: $0, encoding: .utf8) } ?? "null"
            let proceedJavaScript = "window.__proceedNav(\(serializedBody));"

            if let targetURL = URL(string: urlString),
               !browserStore.shouldConfirmNavigation(current: tab.webView?.url, target: targetURL, sourceHost: sourceHost) {
                approvedURLFromJS = targetURL
                tab.webView?.evaluateJavaScript(proceedJavaScript, completionHandler: nil)
                return
            }

            confirmationPresenter.confirmNavigation(
                to: urlString,
                onConfirm: { [weak self] in
                    guard let self else { return }
                    if let targetURL = URL(string: urlString) {
                        self.approvedURLFromJS = targetURL
                    }
                    self.tab.webView?.evaluateJavaScript(proceedJavaScript, completionHandler: nil)
                },
                onCancel: { [weak self] in
                    self?.handleCancelledExternalNavigation()
                }
            )
        }

        private func isSameDocumentNavigation(current: URL?, target: URL) -> Bool {
            guard let current else { return false }

            return current.scheme?.lowercased() == target.scheme?.lowercased()
                && current.host == target.host
                && current.port == target.port
                && current.path == target.path
                && current.query == target.query
        }

        private func matchesApprovedURL(_ approvedURL: URL, requestURL: URL) -> Bool {
            approvedURL == requestURL || (
                approvedURL.host == requestURL.host
                    && approvedURL.path == requestURL.path
                    && approvedURL.query == requestURL.query
            )
        }

        private func handleCancelledExternalNavigation() {
            let context = CancelledExternalNavigationRecoveryContext(
                openerTabID: tab.openerTabID,
                creationSource: tab.creationSource
            )

            guard case let .closeCurrentTabAndReturnToOpener(openerTabID) = CancelledExternalNavigationRecoveryPolicy.action(for: context),
                  let currentIndex = browserStore.index(of: tab.id)
            else {
                return
            }

            DispatchQueue.main.async {
                self.browserStore.closeTab(at: currentIndex)
                self.browserStore.switchToTab(withID: openerTabID)
            }
        }
    }
}

private struct RuntimePreferenceState: Equatable {
    let isMutedGlobal: Bool
    let confirmNavigation: Bool
    let customKeyboardEnabled: Bool
    let shouldInterceptSystemKeyboardForGuide: Bool
}

struct WebInputStateChange: Equatable {
    let isFocused: Bool
    let usesCustomKeyboard: Bool
}

struct CancelledExternalNavigationRecoveryContext: Equatable {
    let openerTabID: UUID?
    let creationSource: BrowserTabCreationSource
}

enum CancelledExternalNavigationRecoveryAction: Equatable {
    case none
    case closeCurrentTabAndReturnToOpener(UUID)
}

struct CancelledExternalNavigationRecoveryPolicy {
    static func action(
        for context: CancelledExternalNavigationRecoveryContext
    ) -> CancelledExternalNavigationRecoveryAction {
        guard let openerTabID = context.openerTabID else {
            return .none
        }

        guard context.creationSource == .pageOpened else {
            return .none
        }

        return .closeCurrentTabAndReturnToOpener(openerTabID)
    }
}
