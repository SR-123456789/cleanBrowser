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
    
    var body: some View {
        VStack(spacing: 0) {
            // WebView部分
            WebViewRepresentable(webView: $webView, isKeyboardVisible: $isKeyboardVisible)
                .ignoresSafeArea(.keyboard)
            
            // カスタムキーボード - アニメーションを簡素化
            if isKeyboardVisible {
                CustomKeyboard(webView: webView)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isKeyboardVisible)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("キーボード") {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isKeyboardVisible.toggle()
                    }
                }
            }
        }
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    @Binding var webView: WKWebView?
    @Binding var isKeyboardVisible: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        
        // WebViewの設定でキーボードを完全に無効化
        webView.scrollView.keyboardDismissMode = .onDrag
        webView.allowsBackForwardNavigationGestures = false
        
        // JavaScript注入の準備 - 完全にシンプルなアプローチ
        let userScript = WKUserScript(
            source: """
                // 最小限のアプローチでキーボード制御
                let focusedElement = null;
                
                document.addEventListener('focusin', function(e) {
                    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') {
                        focusedElement = e.target;
                        // デフォルトキーボードを阻止
                        e.target.setAttribute('readonly', 'readonly');
                        window.webkit.messageHandlers.inputFocused.postMessage('focused');
                    }
                });
                
                document.addEventListener('focusout', function(e) {
                    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') {
                        window.webkit.messageHandlers.inputBlurred.postMessage('blurred');
                    }
                });
                
                // カスタム入力関数 - 極力シンプル
                window.customInsertText = function(text) {
                    if (focusedElement) {
                        focusedElement.removeAttribute('readonly');
                        const start = focusedElement.selectionStart || 0;
                        const value = focusedElement.value || '';
                        focusedElement.value = value.substring(0, start) + text + value.substring(focusedElement.selectionEnd || 0);
                        focusedElement.selectionStart = focusedElement.selectionEnd = start + text.length;
                        focusedElement.setAttribute('readonly', 'readonly');
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
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        
        webView.configuration.userContentController.addUserScript(userScript)
        webView.configuration.userContentController.add(context.coordinator, name: "inputFocused")
        webView.configuration.userContentController.add(context.coordinator, name: "inputBlurred")
        
        // テスト用のHTMLを読み込み
        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body { 
                    font-family: Arial, sans-serif; 
                    padding: 20px; 
                    background: #f5f5f5;
                }
                input, textarea { 
                    width: 100%; 
                    padding: 15px; 
                    margin: 10px 0; 
                    font-size: 16px;
                    border: 2px solid #ddd;
                    border-radius: 8px;
                    background: white;
                    box-sizing: border-box;
                    outline: none;
                }
                input:focus, textarea:focus {
                    border-color: #007AFF;
                    box-shadow: 0 0 0 3px rgba(0, 122, 255, 0.1);
                }
            </style>
        </head>
        <body>
            <h1>🌐 Clean Browser</h1>
            <p>カスタムキーボードで入力してください：</p>
            <input type="text" placeholder="テキスト入力" />
            <textarea placeholder="複数行テキスト" rows="4"></textarea>
            <input type="search" placeholder="検索" />
        </body>
        </html>
        """
        
        webView.loadHTMLString(htmlString, baseURL: nil)
        
        DispatchQueue.main.async {
            self.webView = webView
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKScriptMessageHandler {
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
    
    // ひらがなレイアウト
    let hiraganaRows = [
        ["あ", "い", "う", "え", "お", "は", "ひ", "ふ", "へ", "ほ"],
        ["か", "き", "く", "け", "こ", "ま", "み", "む", "め", "も"],
        ["さ", "し", "す", "せ", "そ", "や", "ゆ", "よ", "ら", "り"],
        ["た", "ち", "つ", "て", "と", "る", "れ", "ろ", "わ", "ん"],
        ["な", "に", "ぬ", "ね", "の", "が", "ぎ", "ぐ", "げ", "ご"]
    ]
    
    // カタカナレイアウト
    let katakanaRows = [
        ["ア", "イ", "ウ", "エ", "オ", "ハ", "ヒ", "フ", "ヘ", "ホ"],
        ["カ", "キ", "ク", "ケ", "コ", "マ", "ミ", "ム", "メ", "モ"],
        ["サ", "シ", "ス", "セ", "ソ", "ヤ", "ユ", "ヨ", "ラ", "リ"],
        ["タ", "チ", "ツ", "テ", "ト", "ル", "レ", "ロ", "ワ", "ン"],
        ["ナ", "ニ", "ヌ", "ネ", "ノ", "ガ", "ギ", "グ", "ゲ", "ゴ"]
    ]
    
    // 英語レイアウト
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
            // キーボードレイアウト切り替えボタン
            HStack(spacing: 8) {
                ForEach(KeyboardLayout.allCases, id: \.self) { layout in
                    Button(action: {
                        currentLayout = layout
                        if layout != .english {
                            isShiftPressed = false
                        }
                    }) {
                        Text(layout.title)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(currentLayout == layout ? .white : .black)
                            .frame(maxWidth: .infinity, minHeight: 32)
                            .background(currentLayout == layout ? Color.blue : Color.gray.opacity(0.3))
                            .cornerRadius(6)
                    }
                }
            }
            .padding(.horizontal)
            
            // メインキーボード
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
            
            // 機能キー行
            HStack(spacing: 6) {
                // Shiftキー（英語モード時のみ）
                if currentLayout == .english {
                    Button(action: {
                        isShiftPressed.toggle()
                    }) {
                        Image(systemName: "shift")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isShiftPressed ? .white : .black)
                            .frame(width: 50, height: 44)
                            .background(isShiftPressed ? Color.blue : Color.gray.opacity(0.3))
                            .cornerRadius(8)
                    }
                }
                
                // スペースキー
                Button(action: {
                    insertText(" ")
                }) {
                    Text("スペース")
                        .font(.caption)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)
                }
                
                // バックスペースキー
                Button(action: {
                    deleteLastCharacter()
                }) {
                    Image(systemName: "delete.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                        .frame(width: 60, height: 44)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)
                }
                
                // エンターキー
                Button(action: {
                    insertText("\n")
                }) {
                    Image(systemName: "return")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 44)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
    
    @ViewBuilder
    private func keyboardGrid(rows: [[String]]) -> some View {
        ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
            HStack(spacing: 3) {
                ForEach(row, id: \.self) { character in
                    Button(action: {
                        var textToInsert = character
                        if currentLayout == .english && !isShiftPressed {
                            textToInsert = character.lowercased()
                        }
                        insertText(textToInsert)
                    }) {
                        Text(currentLayout == .english && !isShiftPressed ? character.lowercased() : character)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(Color.white)
                            .cornerRadius(6)
                            .shadow(radius: 1)
                    }
                }
            }
            .padding(.horizontal, CGFloat(index * 4)) // 段ごとに少しオフセット
        }
    }
    
    @ViewBuilder
    private func englishKeyboard() -> some View {
        ForEach(Array(englishRows.enumerated()), id: \.offset) { index, row in
            HStack(spacing: 3) {
                // 2行目以降は少しインデント
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
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(Color.white)
                            .cornerRadius(6)
                            .shadow(radius: 1)
                    }
                }
                
                if index > 0 {
                    Spacer()
                        .frame(width: CGFloat(index * 15))
                }
            }
        }
    }
    
    private func insertText(_ text: String) {
        let script = "window.customInsertText('\(text)');"
        webView?.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("JavaScript実行エラー: \(error)")
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
