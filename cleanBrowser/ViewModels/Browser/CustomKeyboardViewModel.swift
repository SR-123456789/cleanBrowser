//
//  CustomKeyboardViewModel.swift
//  cleanBrowser
//
//  ViewModel for CustomKeyboard. Manages keyboard input logic.
//

import SwiftUI
import WebKit

final class CustomKeyboardViewModel: ObservableObject {
    @Published var currentLayout: KeyboardLayout = .hiragana
    @Published var isShiftPressed = false
    
    // サイクル入力の状態
    @Published var lastPressedKey: String? = nil
    @Published var lastPressedKeyIndex: Int = 0
    @Published var lastKeyPressTime: Date = Date()
    
    // 濁点・半濁点機能用の状態変数
    @Published var lastOutputChar: String? = nil
    @Published var lastDakutenPressTime: Date = Date()
    @Published var dakutenPressCount: Int = 0
    
    weak var webView: WKWebView?
    
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
    
    // MARK: - キーレイアウトデータ
    
    let hiraganaRows = [
        ["あ", "か", "さ"],
        ["た", "な", "は"],
        ["ま", "や", "ら"],
        ["゛", "わ", "。?!"]
    ]
    
    let katakanaRows = [
        ["ア", "カ", "サ"],
        ["タ", "ナ", "ハ"],
        ["マ", "ヤ", "ラ"],
        ["゛", "ワ", "。?!"]
    ]
    
    let englishRows = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["Z", "X", "C", "V", "B", "N", "M"]
    ]
    
    let numbersRows = [
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        ["!", "@", "#", "$", "%", "^", "&", "*", "(", ")"],
        ["-", "_", "=", "+", "[", "]", ";", ":", "'", "\""],
        [".", ",", "?", "/", "\\", "|", "<", ">", "{", "}"]
    ]
    
    // MARK: - サイクルデータ
    
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
    
    let katakanaCycles: [String: [String]] = [
        "ア": ["ア", "イ", "ウ", "エ", "オ"],
        "カ": ["カ", "キ", "ク", "ケ", "コ"],
        "サ": ["サ", "シ", "ス", "セ", "ソ"],
        "タ": ["タ", "チ", "ツ", "テ", "ト"],
        "ナ": ["ナ", "ニ", "ヌ", "ネ", "ノ"],
        "ハ": ["ハ", "ヒ", "フ", "ヘ", "ホ"],
        "マ": ["マ", "ミ", "ム", "メ", "モ"],
        "ヤ": ["ヤ", "ユ", "ヨ"],
        "ラ": ["ラ", "リ", "ル", "レ", "ロ"],
        "ワ": ["ワ", "ヲ", "ン", "ー"]
    ]
    
    // MARK: - 濁点・半濁点マッピング
    
    let dakutenMap: [String: String] = [
        "か": "が", "き": "ぎ", "く": "ぐ", "け": "げ", "こ": "ご",
        "さ": "ざ", "し": "じ", "す": "ず", "せ": "ぜ", "そ": "ぞ",
        "た": "だ", "ち": "ぢ", "つ": "づ", "て": "で", "と": "ど",
        "は": "ば", "ひ": "び", "ふ": "ぶ", "へ": "べ", "ほ": "ぼ",
        "う": "ゔ","や":"ゃ", "ゆ":"ゅ", "よ":"ょ",
        // カタカナ
        "カ": "ガ", "キ": "ギ", "ク": "グ", "ケ": "ゲ", "コ": "ゴ",
        "サ": "ザ", "シ": "ジ", "ス": "ズ", "セ": "ゼ", "ソ": "ゾ",
        "タ": "ダ", "チ": "ヂ", "ツ": "ヅ", "テ": "デ", "ト": "ド",
        "ハ": "バ", "ヒ": "ビ", "フ": "ブ", "ヘ": "ベ", "ホ": "ボ",
        "ウ": "ヴ", "ヤ": "ャ", "ユ": "ュ", "ヨ": "ョ"
    ]
    
    let handakutenMap: [String: String] = [
        "は": "ぱ", "ひ": "ぴ", "ふ": "ぷ", "へ": "ぺ", "ほ": "ぽ",
        "ば": "ぱ", "び": "ぴ", "ぶ": "ぷ", "べ": "ぺ", "ぼ": "ぽ",
        
        "ハ": "パ", "ヒ": "ピ", "フ": "プ", "ヘ": "ペ", "ホ": "ポ",
        "バ": "パ", "ビ": "ピ", "ブ": "プ", "ベ": "ペ", "ボ": "ポ"
    ]
    
    // MARK: - 入力ロジック
    
    func handleHiraganaInput(_ character: String) {
        // 日本語入力モードで「゛」キーが押された場合の濁点・半濁点処理
        if (currentLayout == .hiragana || currentLayout == .katakana) && character == "゛" {
            handleDakutenHandakuten()
            return
        }
        
        if currentLayout == .hiragana, let cycle = hiraganaCycles[character] {
            let now = Date()
            if lastPressedKey == character && now.timeIntervalSince(lastKeyPressTime) < 0.5 {
                lastPressedKeyIndex = (lastPressedKeyIndex + 1) % cycle.count
                deleteLastCharacter()
            } else {
                lastPressedKey = character
                lastPressedKeyIndex = 0
            }
            lastKeyPressTime = now
            let outputChar = cycle[lastPressedKeyIndex]
            insertText(outputChar)
            lastOutputChar = outputChar
        } else if currentLayout == .katakana, let cycle = katakanaCycles[character] {
            let now = Date()
            if lastPressedKey == character && now.timeIntervalSince(lastKeyPressTime) < 0.5 {
                lastPressedKeyIndex = (lastPressedKeyIndex + 1) % cycle.count
                deleteLastCharacter()
            } else {
                lastPressedKey = character
                lastPressedKeyIndex = 0
            }
            lastKeyPressTime = now
            let outputChar = cycle[lastPressedKeyIndex]
            insertText(outputChar)
            lastOutputChar = outputChar
        } else {
            insertText(character)
            lastOutputChar = character
        }
    }
    
    /// 濁点・半濁点変換処理
    func handleDakutenHandakuten() {
        guard let lastChar = lastOutputChar else {
            print("濁点・半濁点変換: 直前の文字がありません")
            return
        }
        
        let now = Date()
        let timeSinceLastDakuten = now.timeIntervalSince(lastDakutenPressTime)
        
        if timeSinceLastDakuten < 0.5 {
            dakutenPressCount += 1
        } else {
            dakutenPressCount = 1
        }
        
        lastDakutenPressTime = now
        
        var convertedChar: String?
        
        switch dakutenPressCount {
        case 1:
            convertedChar = dakutenMap[lastChar]
            print("濁点変換試行: \(lastChar) -> \(convertedChar ?? "変換なし")")
            
        case 2:
            convertedChar = handakutenMap[lastChar]
            print("半濁点変換試行: \(lastChar) -> \(convertedChar ?? "変換なし")")
            
        default:
            dakutenPressCount = 1
            convertedChar = dakutenMap[lastChar]
            print("濁点変換リセット: \(lastChar) -> \(convertedChar ?? "変換なし")")
        }
        
        if let newChar = convertedChar {
            deleteLastCharacter()
            insertText(newChar)
            lastOutputChar = newChar
            print("濁点・半濁点変換成功: \(lastChar) -> \(newChar)")
        } else {
            print("濁点・半濁点変換: \(lastChar) は変換対象外です")
        }
    }
    
    func handleEnglishInput(_ character: String) {
        let textToInsert = isShiftPressed ? character : character.lowercased()
        insertText(textToInsert)
        if isShiftPressed {
            isShiftPressed = false
        }
    }
    
    func insertText(_ text: String) {
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
    
    func deleteLastCharacter() {
        let script = "window.customDeleteText();"
        webView?.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("JavaScript実行エラー: \(error)")
            }
        }
    }
    
    func insertSpace() {
        insertText(" ")
    }
    
    func insertNewline() {
        insertText("\n")
    }
    
    var mainAreaHeight: CGFloat {
        switch currentLayout {
        case .hiragana:
            return 225
        case .katakana:
            return 225
        case .english:
            return 160
        case .numbers:
            return 160
        }
    }
}
