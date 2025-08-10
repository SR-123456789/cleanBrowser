//
//  BrowserView.swift
//  cleanBrowser
//
//  Created by NakataniSoshi on 2025/08/01.
//

import SwiftUI
import WebKit
import GoogleMobileAds

struct BrowserView: View {
    @StateObject private var tabManager = TabManager()
    @State private var isKeyboardVisible = false
    @State private var showPINSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // ブラウザツールバー
            if let activeTab = tabManager.activeTab {
                BrowserToolbar(
                    currentURL: Binding(
                        get: { activeTab.url },
                        set: { activeTab.url = $0 }
                    ),
                    canGoBack: Binding(
                        get: { activeTab.canGoBack },
                        set: { activeTab.canGoBack = $0 }
                    ),
                    canGoForward: Binding(
                        get: { activeTab.canGoForward },
                        set: { activeTab.canGoForward = $0 }
                    ),
                    isLoading: Binding(
                        get: { activeTab.isLoading },
                        set: { activeTab.isLoading = $0 }
                    ),
                    pageTitle: Binding(
                        get: { activeTab.title },
                        set: { activeTab.title = $0 }
                    ),
                    webView: activeTab.webView,
                    tabCount: tabManager.tabs.count,
                    showTabOverview: $tabManager.showTabOverview,
                    showPINSettings: $showPINSettings
                )
            }
            
            // WebView部分
            if let activeTab = tabManager.activeTab {
                WebViewRepresentable(
                    tab: activeTab,
                    isKeyboardVisible: $isKeyboardVisible
                )
                .id(activeTab.id) // タブのIDをキーとして使用してビューの再生成を強制
                .ignoresSafeArea(.keyboard)
            }
            
            // AdMobバナー広告（最小高さ50pt）
            AdMobBannerView()
                .frame(height: 50)
                .background(Color(.systemBackground))
            
            // カスタムキーボード
            if isKeyboardVisible {
                CustomKeyboard(
                    webView: tabManager.activeTab?.webView,
                    isKeyboardVisible: $isKeyboardVisible
                )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isKeyboardVisible)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(tabManager.activeTab?.title ?? "Clean Browser")
        .navigationBarHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("キーボード") {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isKeyboardVisible.toggle()
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button("テスト") {
                    print("現在のキーボード状態: \(isKeyboardVisible)")
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isKeyboardVisible = true
                    }
                }
            }
        }
        .sheet(isPresented: $tabManager.showTabOverview) {
            TabOverviewView(tabManager: tabManager, isPresented: $tabManager.showTabOverview)
        }
        .sheet(isPresented: $showPINSettings) {
            PINSettingsView()
        }
    }
}

struct BrowserToolbar: View {
    @Binding var currentURL: String
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var isLoading: Bool
    @Binding var pageTitle: String
    let webView: WKWebView?
    var tabCount: Int
    @Binding var showTabOverview: Bool
    @Binding var showPINSettings: Bool
    
    @State private var addressText = ""
    @State private var isEditingAddress = false
    
    var body: some View {
        VStack(spacing: 0) {
            // メインツールバー
            HStack(spacing: 16) {
                // 左側のナビゲーションボタン群
                HStack(spacing: 12) {
                    // 戻るボタン
                    Button(action: {
                        webView?.goBack()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(canGoBack ? .primary : .secondary)
                            .frame(width: 44, height: 44)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Circle())
                    }
                    .disabled(!canGoBack)
                    
                    // 進むボタン
                    Button(action: {
                        webView?.goForward()
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(canGoForward ? .primary : .secondary)
                            .frame(width: 44, height: 44)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Circle())
                    }
                    .disabled(!canGoForward)
                }
                
                // 中央のアドレスバー
                HStack(spacing: 8) {
                    // セキュリティアイコン
                    Image(systemName: currentURL.hasPrefix("https://") ? "lock.fill" : "lock.open")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(currentURL.hasPrefix("https://") ? .green : .orange)
                    
                    // URL表示・編集
                    if isEditingAddress {
                        TextField("URLまたは検索語を入力", text: $addressText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 14, weight: .medium))
                            .onSubmit {
                                loadURL(addressText)
                                isEditingAddress = false
                            }
                            .onAppear {
                                addressText = currentURL
                            }
                    } else {
                        HStack {
                            Text(formatURL(currentURL))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .onTapGesture {
                            isEditingAddress = true
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .onTapGesture {
                    if !isEditingAddress {
                        isEditingAddress = true
                    }
                }
                
                // 右側のアクションボタン群
                HStack(spacing: 12) {
                    // リロード/ストップボタン
                    Button(action: {
                        if isLoading {
                            webView?.stopLoading()
                        } else {
                            webView?.reload()
                        }
                    }) {
                        Image(systemName: isLoading ? "xmark" : "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Circle())
                    }
                    
                    // タブ管理ボタン（共有ボタンを置き換え）
                    Button(action: {
                        showTabOverview.toggle()
                    }) {
                        ZStack {
                            // タブアイコンの背景
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.primary, lineWidth: 2)
                                .frame(width: 20, height: 16)
                            
                            // タブ数を表示（9以下の場合のみ）
                            if tabCount <= 9 {
                                Text("\(tabCount)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.primary)
                            } else {
                                Text("∞")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                        }
                        .frame(width: 44, height: 44)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Circle())
                    }
                    
                    // 設定ボタン
                    Button(action: {
                        showPINSettings.toggle()
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // プログレスバー
            if isLoading {
                Rectangle()
                    .fill(Color.blue)
                    .frame(height: 2)
                    .animation(.easeInOut(duration: 0.3), value: isLoading)
            }
        }
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        )
    }
    
    private func loadURL(_ urlString: String) {
        guard let webView = webView else { return }
        
        var finalURL = urlString
        
        // URLが完全でない場合の処理
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            if urlString.contains(".") && !urlString.contains(" ") {
                // ドメイン名っぽい場合はhttps://を付ける
                finalURL = "https://" + urlString
            } else {
                // それ以外は検索クエリとして扱う
                let encodedQuery = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                finalURL = "https://www.google.com/search?q=" + encodedQuery
            }
        }
        
        if let url = URL(string: finalURL) {
            webView.load(URLRequest(url: url))
        }
    }
    
    private func formatURL(_ url: String) -> String {
        if let urlComponents = URLComponents(string: url) {
            return urlComponents.host ?? url
        }
        return url
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    @ObservedObject var tab: BrowserTab
    @Binding var isKeyboardVisible: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        
        // ナビゲーションデリゲートを設定
        webView.navigationDelegate = context.coordinator
        
        // WebViewの設定
        webView.scrollView.keyboardDismissMode = .onDrag
        webView.allowsBackForwardNavigationGestures = true
        
        // iOSキーボードを無効化
        webView.scrollView.isScrollEnabled = true
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        
        // JavaScript注入でinput要素のキーボード表示を無効化
        let userScript = WKUserScript(
            source: """
                (function() {
                    let focusedElement = null;

                    document.addEventListener('focusin', function(e) {
                        if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') {
                            focusedElement = e.target;
                            e.target.setAttribute('readonly', 'readonly');
                            e.target.setAttribute('inputmode', 'none');
                            e.target.style.caretColor = 'transparent';
                            window.webkit.messageHandlers.inputFocused.postMessage('focused');
                        }
                    });

                    document.addEventListener('focusout', function(e) {
                        if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') {
                            window.webkit.messageHandlers.inputBlurred.postMessage('blurred');
                        }
                    });

                    window.customInsertText = function(text) {
                        if (focusedElement) {
                            focusedElement.removeAttribute('readonly');
                            const start = focusedElement.selectionStart || 0;
                            const value = focusedElement.value || '';
                            focusedElement.value = value.substring(0, start) + text + value.substring(focusedElement.selectionEnd || 0);
                            focusedElement.selectionStart = focusedElement.selectionEnd = start + text.length;
                            focusedElement.setAttribute('readonly', 'readonly');

                            if (text === '\\n') {
                                submitForm();
                            }
                        }
                    };

                    window.customDeleteText = function() {
                        if (focusedElement) {
                            focusedElement.removeAttribute('readonly');
                            const start = focusedElement.selectionStart || 0;
                            const value = focusedElement.value || '';
                            if (start > 0) {
                                focusedElement.value = value.substring(0, start - 1) + value.substring(focusedElement.selectionEnd || 0);
                                focusedElement.selectionStart = focusedElement.selectionEnd = start - 1;
                            }
                            focusedElement.setAttribute('readonly', 'readonly');
                        }
                    };

                    function submitForm() {
                        if (focusedElement) {
                            let form = focusedElement.closest('form');
                            if (form) {
                                form.submit();
                            } else {
                                const searchButton = document.querySelector('input[type="submit"]') ||
                                                       document.querySelector('button[type="submit"]') ||
                                                       document.querySelector('[aria-label*="検索"]') ||
                                                       document.querySelector('[aria-label*="Search"]') ||
                                                       document.querySelector('button:contains("検索")');

                                if (searchButton) {
                                    searchButton.click();
                                } else {
                                    const googleSearchBtn = document.querySelector('input[name="btnK"]') ||
                                                           document.querySelector('.FPdoLc input[type="submit"]') ||
                                                           document.querySelector('[data-ved] input[type="submit"]');
                                    if (googleSearchBtn) {
                                        googleSearchBtn.click();
                                    }
                                }
                            }
                        }
                    }
                })();
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        
        webView.configuration.userContentController.addUserScript(userScript)
        webView.configuration.userContentController.add(context.coordinator, name: "inputFocused")
        webView.configuration.userContentController.add(context.coordinator, name: "inputBlurred")
        
        // 最初にGoogleを読み込み
        if let url = URL(string: tab.url) {
            webView.load(URLRequest(url: url))
        }
        
        DispatchQueue.main.async {
            self.tab.webView = webView
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        var parent: WebViewRepresentable
        
        init(_ parent: WebViewRepresentable) {
            self.parent = parent
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            DispatchQueue.main.async {
                switch message.name {
                case "inputFocused":
                    self.parent.isKeyboardVisible = true
                case "inputBlurred":
                    self.parent.isKeyboardVisible = false
                default:
                    break
                }
            }
        }
        
        // ブラウザナビゲーション機能
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.tab.isLoading = true
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.tab.isLoading = false
                self.parent.tab.canGoBack = webView.canGoBack
                self.parent.tab.canGoForward = webView.canGoForward
                
                if let url = webView.url {
                    self.parent.tab.url = url.absoluteString
                }
                
                webView.evaluateJavaScript("document.title") { result, error in
                    if let title = result as? String, !title.isEmpty {
                        DispatchQueue.main.async {
                            self.parent.tab.title = title
                        }
                    }
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.tab.isLoading = false
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.tab.isLoading = false
            }
        }
    }
}

#Preview {
    NavigationView {
        BrowserView()
    }
}
