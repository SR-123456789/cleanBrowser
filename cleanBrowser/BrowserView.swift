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
    @State private var showSettingsSheet = false
    
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
                        showPINSettings: $showPINSettings,
                        showSettingsSheet: $showSettingsSheet
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
            

            
            // カスタムキーボード（設定で無効なら表示しない）
            if isKeyboardVisible && tabManager.customKeyboardEnabled {
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
                    // 設定で無効ならトグルしない
                    guard tabManager.customKeyboardEnabled else { return }
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isKeyboardVisible.toggle()
                    }
                }
                .disabled(!tabManager.customKeyboardEnabled)
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button("設定") { showSettingsSheet = true }
            }
        }
        .sheet(isPresented: $tabManager.showTabOverview) {
            TabOverviewView(tabManager: tabManager, isPresented: $tabManager.showTabOverview)
        }
    .sheet(isPresented: $showPINSettings) { PINSettingsView() }
    .sheet(isPresented: $showSettingsSheet) { SettingsSheet(showPINSettings: $showPINSettings) }
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
    @Binding var showSettingsSheet: Bool
    // isMuted Binding を削除し、tab.isMuted を使用
    @ObservedObject private var tabManager = TabManager.shared
    
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
                    
                    // 設定ボタン（設定シートを開く）
                    Button(action: { showSettingsSheet = true }) {
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
    // 設定シートはBrowserViewの末尾で一元管理
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
            uc.removeScriptMessageHandler(forName: "confirmNav")
            uc.add(context.coordinator, name: "inputFocused")
            uc.add(context.coordinator, name: "inputBlurred")
            uc.add(context.coordinator, name: "confirmNav")
            
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

                    // default to false if not set yet so behavior matches app default
                    if (typeof window.__useCustomKeyboard === 'undefined') { window.__useCustomKeyboard = false; }

                    document.addEventListener('focusin', function(e) {
                        try {
                            if (!(e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA')) return;
                            focusedElement = e.target;
                            if (window.__useCustomKeyboard) {
                                e.target.setAttribute('readonly', 'readonly');
                                e.target.setAttribute('inputmode', 'none');
                                e.target.style.caretColor = 'transparent';
                            } else {
                                // ensure default keyboard allowed
                                e.target.removeAttribute('readonly');
                                e.target.removeAttribute('inputmode');
                                e.target.style.caretColor = '';
                            }
                            window.webkit.messageHandlers.inputFocused.postMessage('focused');
                        } catch (ex) {}
                    });

                    document.addEventListener('focusout', function(e) {
                        try {
                            if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') {
                                window.webkit.messageHandlers.inputBlurred.postMessage('blurred');
                            }
                        } catch (ex) {}
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

                // ナビゲーションガード（リンククリック＆History APIのフック）
                let navGuardScript = WKUserScript(
                        source: """
                        (function(){try{
                            if(window.__navGuardInstalled) return; window.__navGuardInstalled=true; window.__confirmNavOn=false;
                            function abs(u){ try { return new URL(u, location.href).href; } catch(e){ return null; } }
                            // anchor clicks
                            document.addEventListener('click', function(e){
                                try{
                                    if(!window.__confirmNavOn) return;
                                    var el = e.target && e.target.closest ? e.target.closest('a[href]') : null;
                                    if(!el) return;
                                    var href = el.getAttribute('href'); if(!href) return;
                                    if(/^(javascript:|mailto:|tel:)/i.test(href)) return;
                                    var url = abs(href); if(!url) return;
                                    var tgt = el.getAttribute('target'); if(tgt && tgt !== '_self') return;
                                    e.preventDefault();
                                    window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.confirmNav && window.webkit.messageHandlers.confirmNav.postMessage({type:'anchor', url:url, from: location.host});
                                }catch(_){}
                            }, true);

                            // history API
                            (function(){
                                var origPush = history.pushState; var origReplace = history.replaceState;
                                history.pushState = function(state,title,url){
                                    try{
                                        if(window.__confirmNavOn && url){ var u=abs(url); if(u){ window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.confirmNav && window.webkit.messageHandlers.confirmNav.postMessage({type:'history', method:'push', url:u}); return; } }
                                    }catch(_){}
                                    return origPush.apply(this, arguments);
                                };
                                history.replaceState = function(state,title,url){
                                    try{
                                        if(window.__confirmNavOn && url){ var u=abs(url); if(u){ window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.confirmNav && window.webkit.messageHandlers.confirmNav.postMessage({type:'history', method:'push', url:u, from: location.host}); return; } }
                                    }catch(_){}
                                    return origReplace.apply(this, arguments);
                                };
                                window.__proceedNav = function(payload){ try{ var t=payload&&payload.type; var m=payload&&payload.method; var u=payload&&payload.url; if(!u) return; if(t==='history'){ if(m==='replace'){ history.replaceState({},'',u); } else { history.pushState({},'',u); } } else { location.assign(u); } }catch(_){}}
                                    try{
                                        if(window.__confirmNavOn && url){ var u=abs(url); if(u){ window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.confirmNav && window.webkit.messageHandlers.confirmNav.postMessage({type:'history', method:'replace', url:u, from: location.host}); return; } }
                        """,
                        injectionTime: .atDocumentStart,
                        forMainFrameOnly: true
                )
                webView.configuration.userContentController.addUserScript(navGuardScript)

        // デリゲートとメッセージハンドラ設定
        webView.navigationDelegate = context.coordinator
    let uc = webView.configuration.userContentController
    uc.add(context.coordinator, name: "inputFocused")
    uc.add(context.coordinator, name: "inputBlurred")
    uc.add(context.coordinator, name: "confirmNav")

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
    // ナビゲーション確認の再入防止フラグ
    private var bypassNextDecision = false
    // JS経由で承認済みのURL（次回のネイティブ判定で自動許可）
    private var approvedURLFromJS: URL?

        // 検索エンジンドメインの簡易判定
        private func isSearchEngineHost(_ host: String?) -> Bool {
            guard let h = host?.lowercased() else { return false }
            return h == "www.google.com" || h == "google.com" || h.hasSuffix(".google.com")
                || h == "www.bing.com" || h == "bing.com"
                || h == "search.yahoo.co.jp" || h == "yahoo.co.jp" || h.hasSuffix(".yahoo.co.jp")
        }

        // 確認が必要かどうかの判定
        private func needsConfirm(current: URL?, to reqURL: URL, fromHost: String?) -> Bool {
            // スキーマチェックは呼び出し側で済
            // 1) 同一ドメイン内は確認なし
            if let cur = current, cur.host?.lowercased() == reqURL.host?.lowercased() {
                return false
            }
            // 2) 検索エンジン発→外部でも確認なし（直遷移許可）
            if isSearchEngineHost(fromHost) {
                return false
            }
            return true
        }
        
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
                case "confirmNav":
                    guard TabManager.shared.confirmNavigation else { return }
                    guard let body = message.body as? [String: Any], let url = body["url"] as? String else { return }
                    let fromHost = body["from"] as? String
                    let target = url
                    let proceedJS = "window.__proceedNav(" + (try? String(data: JSONSerialization.data(withJSONObject: body), encoding: .utf8))! + ");"
                    // from が検索エンジン or 同一ドメインの場合は確認なしで進める
                    if let u = URL(string: url) {
                        let allowWithoutDialog = !self.needsConfirm(current: self.parent.tab.webView?.url, to: u, fromHost: fromHost)
                        if allowWithoutDialog {
                            self.approvedURLFromJS = u
                            self.parent.tab.webView?.evaluateJavaScript(proceedJS, completionHandler: nil)
                            return
                        }
                    }
                    let alert = UIAlertController(title: "移動しますか？", message: target, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: { _ in }))
                    alert.addAction(UIAlertAction(title: "移動", style: .default, handler: { _ in
                        // ユーザー許可後、JS側を進める
            if let u = URL(string: url) { self.approvedURLFromJS = u }
                        self.parent.tab.webView?.evaluateJavaScript(proceedJS, completionHandler: nil)
                    }))
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let root = scene.keyWindow?.rootViewController {
                        root.present(alert, animated: true, completion: nil)
                    } else if let root = UIApplication.shared.windows.first?.rootViewController {
                        root.present(alert, animated: true, completion: nil)
                    }
                default:
                    break
                }
            }
        }
        
        // ブラウザナビゲーション機能
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // 既にバイパス許可中ならそのまま許可
            if bypassNextDecision {
                bypassNextDecision = false
                decisionHandler(.allow)
                return
            }

            // 設定がOFFならそのまま許可
            guard TabManager.shared.confirmNavigation else {
                decisionHandler(.allow)
                return
            }

            // メインフレーム以外は対象外（iframeなど）
            let isMainFrame = navigationAction.targetFrame?.isMainFrame ?? true
            guard isMainFrame else {
                decisionHandler(.allow)
                return
            }

            guard let reqURL = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            // http/https 以外（about:, data:, blob:, file: 等）は対象外
            let scheme = (reqURL.scheme ?? "").lowercased()
            guard scheme == "http" || scheme == "https" else {
                decisionHandler(.allow)
                return
            }

            // 同一ドキュメント内の移動（#アンカーなど）は対象外
            if let current = webView.url {
                let sameDoc = current.scheme?.lowercased() == reqURL.scheme?.lowercased()
                    && current.host == reqURL.host
                    && current.port == reqURL.port
                    && current.path == reqURL.path
                    && current.query == reqURL.query
                if sameDoc {
                    decisionHandler(.allow)
                    return
                }
            }

            // 検索エンジン発や同一ドメイン内は確認なし
            let fromHost = webView.url?.host
            if !self.needsConfirm(current: webView.url, to: reqURL, fromHost: fromHost) {
                decisionHandler(.allow)
                return
            }

            // JS承認済みURLなら自動許可（ダブルダイアログ回避）
            if let approved = approvedURLFromJS {
                if approved == reqURL || (
                    approved.host == reqURL.host &&
                    approved.path == reqURL.path &&
                    approved.query == reqURL.query
                ) {
                    approvedURLFromJS = nil
                    decisionHandler(.allow)
                    return
                }
            }

            // 確認アラートを表示（ユーザー操作/JS起因どちらも対象）
            let target = reqURL.absoluteString
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "移動しますか？", message: target, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: { _ in
                    decisionHandler(.cancel)
                }))
                alert.addAction(UIAlertAction(title: "移動", style: .default, handler: { _ in
                    // 次のdecidePolicyは許可して再実行させる
                    self.bypassNextDecision = true
                    webView.load(navigationAction.request)
                    decisionHandler(.cancel)
                }))

                // 最前面のUIViewControllerを取得して表示
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let root = scene.keyWindow?.rootViewController {
                    root.present(alert, animated: true, completion: nil)
                } else if let root = UIApplication.shared.windows.first?.rootViewController {
                    root.present(alert, animated: true, completion: nil)
                } else {
                    decisionHandler(.allow)
                }
            }
        }
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

                // JS 側へ確認トグル状態を伝搬
                let on = TabManager.shared.confirmNavigation ? "true" : "false"
                webView.evaluateJavaScript("window.__confirmNavOn = " + on + ";", completionHandler: nil)
                // カスタムキーボードの使用フラグを伝搬
                let useCustom = TabManager.shared.customKeyboardEnabled ? "true" : "false"
                webView.evaluateJavaScript("window.__useCustomKeyboard = " + useCustom + ";", completionHandler: nil)
                if !TabManager.shared.customKeyboardEnabled {
                    // フラグを切った場合はreadonly属性を外してフォーカスを復帰させ、ネイティブキーボードが出るようにする
                    let restoreJS = "(function(){ try{ var el = document.activeElement; if(el && (el.tagName==='INPUT' || el.tagName==='TEXTAREA')){ el.removeAttribute('readonly'); el.removeAttribute('inputmode'); el.style.caretColor=''; el.focus(); } }catch(e){} })();"
                    webView.evaluateJavaScript(restoreJS, completionHandler: nil)
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
