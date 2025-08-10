import SwiftUI
import WebKit

struct CustomKeyboard: View {
    let webView: WKWebView?
    
    @State private var currentLayout: KeyboardLayout = .hiragana
    @State private var isShiftPressed = false
    @State private var lastPressedKey: String? = nil
    @State private var lastPressedKeyIndex: Int = 0
    @State private var lastKeyPressTime: Date = Date()
    @Binding var isKeyboardVisible: Bool
    
    // 濁点・半濁点機能用の状態変数
    @State private var lastOutputChar: String? = nil
    @State private var lastDakutenPressTime: Date = Date()
    @State private var dakutenPressCount: Int = 0

    
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
        ["あ", "か", "さ"],
        ["た", "な", "は"],
        ["ま", "や", "ら"],
        ["゛", "わ", "。?!"]
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
    
    // Hiragana character cycles
    let hiraganaCycles: [String: [String]] = [
        "あ": ["あ", "い", "う", "え", "お"],
        "か": ["か", "き", "く", "け", "こ"],
        "さ": ["さ", "し", "す", "せ", "そ"],
        "た": ["た", "ち", "つ", "て", "と"],
        "な": ["な", "に", "ぬ", "ね", "の"],
        "は": ["は", "ひ", "ふ", "へ", "ほ"],
        "ま": ["ま", "み", "む", "め", "も"],
        "や": ["や", "ゆ", "よ"],
        "ら": ["ら", "り", "る", "れ", "ろ"],
        "わ": ["わ", "を", "ん","ー"]
    ]
    
    // 濁点マッピング
    let dakutenMap: [String: String] = [
        "か": "が", "き": "ぎ", "く": "ぐ", "け": "げ", "こ": "ご",
        "さ": "ざ", "し": "じ", "す": "ず", "せ": "ぜ", "そ": "ぞ",
        "た": "だ", "ち": "ぢ", "つ": "づ", "て": "で", "と": "ど",
        "は": "ば", "ひ": "び", "ふ": "ぶ", "へ": "べ", "ほ": "ぼ",
        "う": "ゔ"
    ]
    
    // 半濁点マッピング
    let handakutenMap: [String: String] = [
        "は": "ぱ", "ひ": "ぴ", "ふ": "ぷ", "へ": "ぺ", "ほ": "ぽ",
        "ば": "ぱ", "び": "ぴ", "ぶ": "ぷ", "べ": "ぺ", "ぼ": "ぽ"
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
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isKeyboardVisible.toggle()
                    }
                }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 40, height: 40)
                        .background(Color.clear)
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
            .frame(height: mainAreaHeight)
            
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
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(rows.flatMap { $0 }, id: \ .self) { character in
                Button(action: {
                    handleHiraganaInput(character)
                }) {
                    Text(character)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 1)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func handleHiraganaInput(_ character: String) {
        // 日本語入力モードで「゛」キーが押された場合の濁点・半濁点処理
        if currentLayout == .hiragana && character == "゛" {
            handleDakutenHandakuten()
            return
        }
        
        if currentLayout == .hiragana, let cycle = hiraganaCycles[character] {
            let now = Date()
            if lastPressedKey == character && now.timeIntervalSince(lastKeyPressTime) < 0.5 {
                // Cycle to the next character and replace the previous character
                lastPressedKeyIndex = (lastPressedKeyIndex + 1) % cycle.count
                deleteLastCharacter() // Remove the last character before inserting the new one
            } else {
                // Start a new cycle or add a new character
                lastPressedKey = character
                lastPressedKeyIndex = 0
            }
            lastKeyPressTime = now
            let outputChar = cycle[lastPressedKeyIndex]
            insertText(outputChar)
            // 最後に出力した文字を保存
            lastOutputChar = outputChar
        } else {
            insertText(character)
            // 最後に出力した文字を保存
            lastOutputChar = character
        }
    }
    
    /// 濁点・半濁点変換処理
    private func handleDakutenHandakuten() {
        guard let lastChar = lastOutputChar else {
            print("濁点・半濁点変換: 直前の文字がありません")
            return
        }
        
        let now = Date()
        let timeSinceLastDakuten = now.timeIntervalSince(lastDakutenPressTime)
        
        // 0.5秒以内の連続押下かチェック
        if timeSinceLastDakuten < 0.5 {
            dakutenPressCount += 1
        } else {
            dakutenPressCount = 1
        }
        
        lastDakutenPressTime = now
        
        var convertedChar: String?
        
        switch dakutenPressCount {
        case 1:
            // 1回目: 濁点変換を試行
            convertedChar = dakutenMap[lastChar]
            print("濁点変換試行: \(lastChar) -> \(convertedChar ?? "変換なし")")
            
        case 2:
            // 2回目: 半濁点変換を試行
            convertedChar = handakutenMap[lastChar]
            print("半濁点変換試行: \(lastChar) -> \(convertedChar ?? "変換なし")")
            
        default:
            // 3回目以降はリセット
            dakutenPressCount = 1
            convertedChar = dakutenMap[lastChar]
            print("濁点変換リセット: \(lastChar) -> \(convertedChar ?? "変換なし")")
        }
        
        // 変換可能な文字が見つかった場合、置換処理を実行
        if let newChar = convertedChar {
            deleteLastCharacter() // 直前の文字を削除
            insertText(newChar)   // 新しい文字を挿入
            lastOutputChar = newChar // 最新の出力文字を更新
            print("濁点・半濁点変換成功: \(lastChar) -> \(newChar)")
        } else {
            print("濁点・半濁点変換: \(lastChar) は変換対象外です")
        }
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
    
    private var mainAreaHeight: CGFloat {
        switch currentLayout {
        case .hiragana:
            return 225   // ← ひらがな
        case .katakana:
            return 225   // ← カタカナ（キー数が多いので少し高め）
        case .english:
            return 150
        case .numbers:
            return 150
        }
    }

}
