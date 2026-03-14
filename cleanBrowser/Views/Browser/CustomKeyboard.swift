import SwiftUI
import WebKit

struct CustomKeyboard: View {
    let webView: WKWebView?
    @StateObject private var viewModel = CustomKeyboardViewModel()
    @Binding var isKeyboardVisible: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // キーボードレイアウト切り替えタブ
            HStack(spacing: 6) {
                
            
                ForEach(CustomKeyboardViewModel.KeyboardLayout.allCases, id: \ .self) { layout in
                    Button(action: {
                        viewModel.currentLayout = layout
                        if layout != .english {
                            viewModel.isShiftPressed = false
                        }
                    }) {
                        Text(layout.title)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(viewModel.currentLayout == layout ? .white : .black)
                            .frame(maxWidth: .infinity, minHeight: 32)
                            .background(viewModel.currentLayout == layout ? Color.blue : Color.gray.opacity(0.2))
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
                switch viewModel.currentLayout {
                case .hiragana:
                    keyboardGrid(rows: viewModel.hiraganaRows)
                case .katakana:
                    keyboardGrid(rows: viewModel.katakanaRows)
                case .english:
                    englishKeyboard()
                case .numbers:
                    numbersKeyboard()
                }
            }
            .frame(height: viewModel.mainAreaHeight)
            
            // 機能キー行
            HStack(spacing: 6) {
                // Shiftキー（英語モード時のみ）
                if viewModel.currentLayout == .english {
                    Button(action: {
                        viewModel.isShiftPressed.toggle()
                    }) {
                        Image(systemName: "shift")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(viewModel.isShiftPressed ? .white : .black)
                            .frame(width: 45, height: 40)
                            .background(viewModel.isShiftPressed ? Color.blue : Color.gray.opacity(0.3))
                            .cornerRadius(6)
                    }
                }
                
                // スペースキー
                Button(action: {
                    viewModel.insertSpace()
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
                    viewModel.deleteLastCharacter()
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
                    viewModel.insertNewline()
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
        .onAppear {
            viewModel.webView = webView
        }
        .onChange(of: webView) { _, newValue in
            viewModel.webView = newValue
        }
    }
    
    @ViewBuilder
    private func keyboardGrid(rows: [[String]]) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(rows.flatMap { $0 }, id: \ .self) { character in
                Button(action: {
                    viewModel.handleHiraganaInput(character)
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
    
    @ViewBuilder
    private func englishKeyboard() -> some View {
        VStack(spacing: 4) {
            ForEach(Array(viewModel.englishRows.enumerated()), id: \ .offset) { index, row in
                HStack(spacing: 3) {
                    // 2行目以降はインデント
                    if index > 0 {
                        Spacer()
                            .frame(width: CGFloat(index * 15))
                    }
                    
                    ForEach(row, id: \ .self) { character in
                        Button(action: {
                            viewModel.handleEnglishInput(character)
                        }) {
                            Text(viewModel.isShiftPressed ? character : character.lowercased())
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, minHeight: 37)
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
    
    private func numbersKeyboard() -> some View {
        VStack(spacing: 4) {
            ForEach(Array(viewModel.numbersRows.enumerated()), id: \ .offset) { index, row in
                HStack(spacing: 3) {
                    // 2行目以降はインデント
                    if index > 0 {
                        Spacer()
                            .frame(width: CGFloat(index * 15))
                    }
                    
                    ForEach(row, id: \ .self) { character in
                        Button(action: {
                            viewModel.insertText(character)
                        }) {
                            Text(viewModel.isShiftPressed ? character : character.lowercased())
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, minHeight: 37)
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
}
