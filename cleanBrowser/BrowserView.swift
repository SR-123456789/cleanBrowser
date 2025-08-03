//
//  BrowserView.swift
//  cleanBrowser
//
//  Created by NakataniSoshi on 2025/08/01.
//

import SwiftUI
import WebKit

struct BrowserView: View {
    @State private var webView: WKWebView?
    @State private var isKeyboardVisible = false
    @State private var currentURL = "https://www.google.com"
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var isLoading = false
    @State private var pageTitle = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // ブラウザツールバー
            BrowserToolbar(
                currentURL: $currentURL,
                canGoBack: $canGoBack,
                canGoForward: $canGoForward,
                isLoading: $isLoading,
                pageTitle: $pageTitle,
                webView: webView
            )
            
            // WebView部分
            WebViewRepresentable(
                webView: $webView,
                isKeyboardVisible: $isKeyboardVisible,
                currentURL: $currentURL,
                canGoBack: $canGoBack,
                canGoForward: $canGoForward,
                isLoading: $isLoading,
                pageTitle: $pageTitle
            )
            .ignoresSafeArea(.keyboard)
            
            // カスタムキーボード
            if isKeyboardVisible {
                CustomKeyboard(webView: webView)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isKeyboardVisible)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(pageTitle.isEmpty ? "Clean Browser" : pageTitle)
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
    }
}

struct BrowserToolbar: View {
    @Binding var currentURL: String
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var isLoading: Bool
    @Binding var pageTitle: String
    let webView: WKWebView?
    
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
                    
                    // シェア/メニューボタン
                    Button(action: {
                        // シェア機能やメニューを開く
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
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
    @Binding var webView: WKWebView?
    @Binding var isKeyboardVisible: Bool
    @Binding var currentURL: String
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var isLoading: Bool
    @Binding var pageTitle: String
    
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
                let focusedElement = null;
                
                console.log('カスタムキーボードスクリプト開始');

                document.addEventListener('focusin', function(e) {
                    console.log('focusin イベント発生:', e.target.tagName, e.target.type);
                    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') {
                        console.log('input/textarea にフォーカス');
                        focusedElement = e.target;
                        e.target.setAttribute('readonly', 'readonly');
                        e.target.setAttribute('inputmode', 'none');
                        e.target.style.caretColor = 'transparent';
                        console.log('メッセージ送信: focused');
                        window.webkit.messageHandlers.inputFocused.postMessage('focused');
                    }
                }, true);

                document.addEventListener('focusout', function(e) {
                    console.log('focusout イベント発生:', e.target.tagName);
                    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') {
                        console.log('メッセージ送信: blurred');
                        window.webkit.messageHandlers.inputBlurred.postMessage('blurred');
                    }
                }, true);

                // すべてのinput要素にinputmode="none"を設定
                function disableKeyboard() {
                    console.log('disableKeyboard 実行');
                    const inputs = document.querySelectorAll('input, textarea');
                    console.log('見つかったinput要素数:', inputs.length);
                    inputs.forEach(input => {
                        input.setAttribute('inputmode', 'none');
                        input.setAttribute('readonly', 'readonly');
                        console.log('input要素を無効化:', input.type, input.placeholder);
                    });
                }

                // ページ読み込み時とDOMの変更時にキーボード無効化を実行
                document.addEventListener('DOMContentLoaded', function() {
                    console.log('DOMContentLoaded');
                    disableKeyboard();
                });
                
                window.addEventListener('load', function() {
                    console.log('window load');
                    disableKeyboard();
                });

                const observer = new MutationObserver(function(mutations) {
                    mutations.forEach(function(mutation) {
                        if (mutation.type === 'childList') {
                            mutation.addedNodes.forEach(function(node) {
                                if (node.nodeType === 1) {
                                    const inputs = node.querySelectorAll ? node.querySelectorAll('input, textarea') : [];
                                    inputs.forEach(input => {
                                        input.setAttribute('inputmode', 'none');
                                        input.setAttribute('readonly', 'readonly');
                                        console.log('新しいinput要素を無効化:', input.type);
                                    });
                                    if (node.tagName === 'INPUT' || node.tagName === 'TEXTAREA') {
                                        node.setAttribute('inputmode', 'none');
                                        node.setAttribute('readonly', 'readonly');
                                        console.log('新しい要素自体がinput:', node.type);
                                    }
                                }
                            });
                        }
                    });
                });

                observer.observe(document.body, {
                    childList: true,
                    subtree: true
                });

                window.customInsertText = function(text) {
                    console.log('customInsertText 実行:', text);
                    if (focusedElement) {
                        focusedElement.removeAttribute('readonly');
                        const start = focusedElement.selectionStart || 0;
                        const value = focusedElement.value || '';
                        focusedElement.value = value.substring(0, start) + text + value.substring(focusedElement.selectionEnd || 0);
                        focusedElement.selectionStart = focusedElement.selectionEnd = start + text.length;
                        focusedElement.setAttribute('readonly', 'readonly');
                        console.log('テキスト挿入完了:', focusedElement.value);

                        if (text === '\\n') {
                            submitForm();
                        }
                    } else {
                        console.log('focusedElement が null');
                    }
                };

                window.customDeleteText = function() {
                    console.log('customDeleteText 実行');
                    if (focusedElement) {
                        focusedElement.removeAttribute('readonly');
                        const start = focusedElement.selectionStart || 0;
                        const value = focusedElement.value || '';
                        if (start > 0) {
                            focusedElement.value = value.substring(0, start - 1) + value.substring(focusedElement.selectionEnd || 0);
                            focusedElement.selectionStart = focusedElement.selectionEnd = start - 1;
                        }
                        focusedElement.setAttribute('readonly', 'readonly');
                        console.log('削除完了:', focusedElement.value);
                    } else {
                        console.log('focusedElement が null');
                    }
                };

                function submitForm() {
                    console.log('submitForm 実行');
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
                
                console.log('カスタムキーボードスクリプト初期化完了');
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        
        webView.configuration.userContentController.addUserScript(userScript)
        webView.configuration.userContentController.add(context.coordinator, name: "inputFocused")
        webView.configuration.userContentController.add(context.coordinator, name: "inputBlurred")
        
        // 最初にGoogleを読み込み
        if let url = URL(string: "https://www.google.com") {
            webView.load(URLRequest(url: url))
        }
        
        DispatchQueue.main.async {
            self.webView = webView
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
                self.parent.isLoading = true
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.canGoBack = webView.canGoBack
                self.parent.canGoForward = webView.canGoForward
                
                if let url = webView.url {
                    self.parent.currentURL = url.absoluteString
                }
                
                webView.evaluateJavaScript("document.title") { result, error in
                    if let title = result as? String, !title.isEmpty {
                        DispatchQueue.main.async {
                            self.parent.pageTitle = title
                        }
                    }
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
    }
}

struct CustomKeyboard: View {
    let webView: WKWebView?
    
    @State private var currentLayout: KeyboardLayout = .hiragana
    @State private var isShiftPressed = false
    
    enum KeyboardLayout: CaseIterable {
        case hiragana, katakana, english, numbers
        
        var title: String {
            switch self {
            case .hiragana: return "あ"
            case .katakana: return "ア"
            case .english: return "ABC"
            case .numbers: return "123"
            }
        }
    }
    
    // ひらがな完全レイアウト
    let hiraganaRows = [
        ["あ", "い", "う", "え", "お", "は", "ひ", "ふ", "へ", "ほ"],
        ["か", "き", "く", "け", "こ", "ま", "み", "む", "め", "も"],
        ["さ", "し", "す", "せ", "そ", "や", "ゆ", "よ", "ら", "り"],
        ["た", "ち", "つ", "て", "と", "る", "れ", "ろ", "わ", "ん"],
        ["な", "に", "ぬ", "ね", "の", "が", "ぎ", "ぐ", "げ", "ご"],
        ["ざ", "じ", "ず", "ぜ", "ぞ", "だ", "ぢ", "づ", "で", "ど"],
        ["ば", "び", "ぶ", "べ", "ぼ", "ぱ", "ぴ", "ぷ", "ぺ", "ぽ"]
    ]
    
    // カタカナ完全レイアウト
    let katakanaRows = [
        ["ア", "イ", "ウ", "エ", "オ", "ハ", "ヒ", "フ", "ヘ", "ホ"],
        ["カ", "キ", "ク", "ケ", "コ", "マ", "ミ", "ム", "メ", "モ"],
        ["サ", "シ", "ス", "セ", "ソ", "ヤ", "ユ", "ヨ", "ラ", "リ"],
        ["タ", "チ", "ツ", "テ", "ト", "ル", "レ", "ロ", "ワ", "ン"],
        ["ナ", "ニ", "ヌ", "ネ", "ノ", "ガ", "ギ", "グ", "ゲ", "ゴ"],
        ["ザ", "ジ", "ズ", "ゼ", "ゾ", "ダ", "ヂ", "ヅ", "デ", "ド"],
        ["バ", "ビ", "ブ", "ベ", "ボ", "パ", "ピ", "プ", "ペ", "ポ"]
    ]
    
    // 英語QWERTYレイアウト
    let englishRows = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["Z", "X", "C", "V", "B", "N", "M"]
    ]
    
    // 数字・記号レイアウト
    let numbersRows = [
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        ["!", "@", "#", "$", "%", "^", "&", "*", "(", ")"],
        ["-", "_", "=", "+", "[", "]", "{", "}", "\\", "|"],
        [";", ":", "'", "\"", ",", ".", "<", ">", "?", "/"]
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            // キーボードレイアウト切り替えタブ
            HStack(spacing: 6) {
                ForEach(KeyboardLayout.allCases, id: \.self) { layout in
                    Button(action: {
                        currentLayout = layout
                        if layout != .english {
                            isShiftPressed = false
                        }
                    }) {
                        Text(layout.title)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(currentLayout == layout ? .white : .black)
                            .frame(maxWidth: .infinity, minHeight: 32)
                            .background(currentLayout == layout ? Color.blue : Color.gray.opacity(0.2))
                            .cornerRadius(6)
                    }
                }
            }
            .padding(.horizontal)
            
            // メインキーボードエリア
            ScrollView(.vertical, showsIndicators: false) {
                switch currentLayout {
                case .hiragana:
                    keyboardGrid(rows: hiraganaRows)
                case .katakana:
                    keyboardGrid(rows: katakanaRows)
                case .english:
                    englishKeyboard()
                case .numbers:
                    keyboardGrid(rows: numbersRows)
                }
            }
            .frame(maxHeight: 200)
            
            // 機能キー行
            HStack(spacing: 6) {
                // Shiftキー（英語モード時のみ）
                if currentLayout == .english {
                    Button(action: {
                        isShiftPressed.toggle()
                    }) {
                        Image(systemName: "shift")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isShiftPressed ? .white : .black)
                            .frame(width: 45, height: 40)
                            .background(isShiftPressed ? Color.blue : Color.gray.opacity(0.3))
                            .cornerRadius(6)
                    }
                }
                
                // スペースキー
                Button(action: {
                    insertText(" ")
                }) {
                    Text("スペース")
                        .font(.caption)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(6)
                }
                
                // バックスペースキー
                Button(action: {
                    deleteLastCharacter()
                }) {
                    Image(systemName: "delete.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black)
                        .frame(width: 50, height: 40)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(6)
                }
                
                // エンターキー
                Button(action: {
                    insertText("\n")
                }) {
                    Image(systemName: "return")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 40)
                        .background(Color.blue)
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    @ViewBuilder
    private func keyboardGrid(rows: [[String]]) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 10), spacing: 4) {
            ForEach(rows.flatMap { $0 }, id: \.self) { character in
                Button(action: {
                    var textToInsert = character
                    if currentLayout == .english && !isShiftPressed {
                        textToInsert = character.lowercased()
                    }
                    insertText(textToInsert)
                }) {
                    Text(currentLayout == .english && !isShiftPressed ? character.lowercased() : character)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, minHeight: 35)
                        .background(Color.white)
                        .cornerRadius(4)
                        .shadow(radius: 0.5)
                }
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func englishKeyboard() -> some View {
        VStack(spacing: 4) {
            ForEach(Array(englishRows.enumerated()), id: \.offset) { index, row in
                HStack(spacing: 3) {
                    // 2行目以降はインデント
                    if index > 0 {
                        Spacer()
                            .frame(width: CGFloat(index * 15))
                    }
                    
                    ForEach(row, id: \.self) { character in
                        Button(action: {
                            let textToInsert = isShiftPressed ? character : character.lowercased()
                            insertText(textToInsert)
                            if isShiftPressed {
                                isShiftPressed = false // 一文字入力後にShift解除
                            }
                        }) {
                            Text(isShiftPressed ? character : character.lowercased())
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, minHeight: 35)
                                .background(Color.white)
                                .cornerRadius(4)
                                .shadow(radius: 0.5)
                        }
                    }
                    
                    if index > 0 {
                        Spacer()
                            .frame(width: CGFloat(index * 15))
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func insertText(_ text: String) {
        // 改行文字とその他の特殊文字をエスケープ
        let escapedText = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
        
        let script = "window.customInsertText('\(escapedText)');"
        webView?.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("JavaScript実行エラー: \(error)")
            } else {
                print("テキスト挿入成功: \(text)")
            }
        }
    }
    
    private func deleteLastCharacter() {
        let script = "window.customDeleteText();"
        webView?.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("JavaScript実行エラー: \(error)")
            }
        }
    }
}

#Preview {
    NavigationView {
        BrowserView()
    }
}
