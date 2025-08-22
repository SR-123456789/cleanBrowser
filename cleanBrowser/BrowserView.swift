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
    @StateObject private var tabManager = TabManager.shared
    @State private var isKeyboardVisible = false
    @State private var showPINSettings = false
    
    var body: some View {
            VStack(spacing: 0) {
                // ブラウザツールバー
                if let activeTab = tabManager.activeTab {
                    BrowserToolbar(
                        tab: activeTab,
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
                
                // WebView部分
                if let activeTab = tabManager.activeTab {
                    WebViewRepresentable(
                        tab: activeTab,
                        isKeyboardVisible: $isKeyboardVisible
                    )
                    .id(activeTab.id) // タブIDでビュー差し替え（WebView本体は再利用）
                    .ignoresSafeArea(.keyboard)
                }
            }
            

            
            // カスタムキーボード
            if isKeyboardVisible {
                CustomKeyboard(
                    webView: tabManager.activeTab?.webView,
                    isKeyboardVisible: $isKeyboardVisible
                )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
                // AdMobバナー広告（最小高さ50pt）
            AdMobBannerView()
                .frame(height: 50)
                .background(Color(.systemBackground))
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
    @ObservedObject var tab: BrowserTab // 追加: 観測してUI更新
    @Binding var currentURL: String
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var isLoading: Bool
    @Binding var pageTitle: String
    let webView: WKWebView?
    var tabCount: Int
    @Binding var showTabOverview: Bool
    @Binding var showPINSettings: Bool
    // isMuted Binding を削除し、tab.isMuted を使用
    
    @State private var addressText = ""
    @State private var isEditingAddress = false
    
    // UI constants
    private enum UI {
        static let buttonSize: CGFloat = 36
        static let iconSize: CGFloat = 16
        static let hSpacing: CGFloat = 12
        static let toolbarHPadding: CGFloat = 12
        static let toolbarVPadding: CGFloat = 8
        static let addressCorner: CGFloat = 12
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // メインツールバー
            HStack(spacing: UI.hSpacing) {
                // 左側のナビゲーションボタン群
                HStack(spacing: UI.hSpacing) {
                    // 戻るボタン
                    Button(action: { webView?.goBack() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: UI.iconSize, weight: .medium))
                            .foregroundColor(canGoBack ? .primary : .secondary)
                            .frame(width: UI.buttonSize, height: UI.buttonSize)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Circle())
                    }
                    .disabled(!canGoBack)
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")
                    
                    // 進むボタン
                    Button(action: { webView?.goForward() }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: UI.iconSize, weight: .medium))
                            .foregroundColor(canGoForward ? .primary : .secondary)
                            .frame(width: UI.buttonSize, height: UI.buttonSize)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Circle())
                    }
                    .disabled(!canGoForward)
                    .buttonStyle(.plain)
                    .accessibilityLabel("Forward")
                }
                
                // 中央のアドレスバー
                HStack(spacing: 8) {
                    // セキュリティアイコン
                    Image(systemName: currentURL.hasPrefix("https://") ? "lock.fill" : "lock.open")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(currentURL.hasPrefix("https://") ? .green : .orange)
                    
                    // URL表示・編集
                    if isEditingAddress {
                        TextField("Enter URL or search", text: $addressText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14, weight: .medium))
                            .submitLabel(.go)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onSubmit {
                                loadURL(addressText)
                                isEditingAddress = false
                            }
                            .onAppear { addressText = currentURL }
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
                        .contentShape(Rectangle())
                        .onTapGesture { isEditingAddress = true }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(UI.addressCorner)
                
                // 右側のアクションボタン群
                HStack(spacing: UI.hSpacing) {
                    // ミュート切り替えボタン（アプリ全体）
                    Button(action: {
                        let newMuted = !TabManager.shared.isMutedGlobal
                        TabManager.shared.applyMuteToAllTabs(newMuted)
                    }) {
                        Image(systemName: TabManager.shared.isMutedGlobal ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: UI.iconSize, weight: .medium))
                            .foregroundColor(TabManager.shared.isMutedGlobal ? .red : .primary)
                            .frame(width: UI.buttonSize, height: UI.buttonSize)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(TabManager.shared.isMutedGlobal ? "Unmute" : "Mute")
                    
                    // 設定ボタン
                    Button(action: { showPINSettings.toggle() }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: UI.iconSize, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(width: UI.buttonSize, height: UI.buttonSize)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Settings")
                    
                    // タブ管理ボタン
                    Button(action: { showTabOverview.toggle() }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.primary, lineWidth: 2)
                                .frame(width: 16, height: 12)
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
                        .frame(width: UI.buttonSize, height: UI.buttonSize)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Tabs")
                    
                }
            }
            .padding(.horizontal, UI.toolbarHPadding)
            .padding(.vertical, UI.toolbarVPadding)
            
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
    
    private func setMuted(_ muted: Bool) {
        guard let webView else { return }
        let js = WebViewRepresentable.muteJS(muted)
        webView.evaluateJavaScript(js, completionHandler: nil)
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
    
    // JS generator for muting/unmuting all media elements and future ones
    static func muteJS(_ muted: Bool) -> String {
        let flag = muted ? "true" : "false"
        return """
        (function(){try{
          var m=
        """ + flag + """
        ;window.__appMuted=m;
          var apply=function(el){try{if(!el)return; if(m){ if(el.dataset.prevvol===undefined){el.dataset.prevvol=el.volume;} el.muted=true; el.volume=0; } else { el.muted=false; if(el.dataset.prevvol!==undefined){el.volume=Number(el.dataset.prevvol); delete el.dataset.prevvol;} else { el.volume=1; } }}catch(e){}};
          var list=document.querySelectorAll('audio,video'); if(list){ list.forEach(apply); }
          if(!window.__appMuteInstalled){ window.__appMuteInstalled=true; 
            var obs=new MutationObserver(function(muts){ muts.forEach(function(mu){ (mu.addedNodes||[]).forEach(function(n){ try{ if(n && (n.tagName==='AUDIO'||n.tagName==='VIDEO')){ apply(n); } else if(n && n.querySelectorAll){ n.querySelectorAll('audio,video').forEach(apply); } }catch(e){} }); }); });
            obs.observe(document.documentElement||document.body,{childList:true,subtree:true});
            document.addEventListener('play',function(e){ var el=e.target; if(el&&(el.tagName==='AUDIO'||el.tagName==='VIDEO')&&window.__appMuted){ apply(el); } }, true);
          }
        }catch(e){}})();
        """
    }
    
    func makeUIView(context: Context) -> WKWebView {
        // 既存のwebViewがあればそれを返す。なければ生成して保存。
        if let existing = tab.webView {
            // 再アタッチ時もナビゲーションデリゲートだけ更新
            existing.navigationDelegate = context.coordinator
            let uc = existing.configuration.userContentController
            uc.removeScriptMessageHandler(forName: "inputFocused")
            uc.removeScriptMessageHandler(forName: "inputBlurred")
            uc.add(context.coordinator, name: "inputFocused")
            uc.add(context.coordinator, name: "inputBlurred")
            
            if existing.url == nil, let url = URL(string: tab.url) {
                existing.load(URLRequest(url: url))
            }
            return existing
        }

        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)

        // WebViewの設定
        webView.scrollView.keyboardDismissMode = .onDrag
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.isScrollEnabled = true
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        // JavaScript注入でinput要素のキーボード表示を無効化（初期生成時のみ）
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

        // デリゲートとメッセージハンドラ設定
        webView.navigationDelegate = context.coordinator
        let uc = webView.configuration.userContentController
        uc.add(context.coordinator, name: "inputFocused")
        uc.add(context.coordinator, name: "inputBlurred")

        // 初回URL読み込み
        if let url = URL(string: tab.url) {
            webView.load(URLRequest(url: url))
        }

        // 生成したwebViewを保持
        self.tab.webView = webView
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
                
                // 再適用: アプリ全体のミュートが有効なら適用
                if TabManager.shared.isMutedGlobal {
                    webView.evaluateJavaScript(WebViewRepresentable.muteJS(true), completionHandler: nil)
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
