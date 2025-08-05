import SwiftUI
import WebKit

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
        ["-", "_", "=", "+", "[", "]", "{", "}", "\\", "|"]
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            // キーボードレイアウト切り替えタブ
            HStack(spacing: 6) {
                ForEach(KeyboardLayout.allCases, id: \ .self) { layout in
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
                    threeByFourJapaneseKeyboard()
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
            ForEach(rows.flatMap { $0 }, id: \ .self) { character in
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
            ForEach(Array(englishRows.enumerated()), id: \ .offset) { index, row in
                HStack(spacing: 3) {
                    // 2行目以降はインデント
                    if index > 0 {
                        Spacer()
                            .frame(width: CGFloat(index * 15))
                    }
                    
                    ForEach(row, id: \ .self) { character in
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
    
    @ViewBuilder
    private func threeByFourJapaneseKeyboard() -> some View {
        let keys = [
            ["あ", "か", "さ"],
            ["た", "な", "は"],
            ["ま", "や", "ら"],
            ["わ", "^_^", "。？！"]
        ]

        VStack(spacing: 8) {
            ForEach(keys, id: \ .self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \ .self) { key in
                        Button(action: {
                            insertText(key)
                        }) {
                            Text(key)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(Color.white)
                                .cornerRadius(6)
                                .shadow(radius: 0.5)
                        }
                    }
                }
            }

            // Special keys row
            HStack(spacing: 6) {
                Button(action: {
                    deleteLastCharacter()
                }) {
                    Image(systemName: "delete.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                        .frame(width: 50, height: 50)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(6)
                }

                Button(action: {
                    insertText(" ")
                }) {
                    Text("空白")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(6)
                }

                Button(action: {
                    insertText("\n")
                }) {
                    Text("改行")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.blue)
                        .cornerRadius(6)
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
