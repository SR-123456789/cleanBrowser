import SwiftUI

struct ContentView: View {
    @State private var isUnlocked = false
    @State private var pinInput = ""
    @State private var showError = false
    private let correctPIN = "1234" // 実際のアプリでは安全な方法で管理

    var body: some View {
        if isUnlocked {
            BrowserView()
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetToPIN"))) { _ in
                    // アプリ切り替え後にPIN入力画面に戻る
                    isUnlocked = false
                    pinInput = ""
                    showError = false
                }
        } else {
            PINEntryScreen(
                pinInput: $pinInput,
                showError: $showError,
                onPINEntered: { pin in
                    if pin == correctPIN {
                        withAnimation {
                            isUnlocked = true
                        }
                    } else {
                        showError = true
                        pinInput = ""
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showError = false
                        }
                    }
                }
            )
        }
    }
}

struct PINEntryScreen: View {
    @Binding var pinInput: String
    @Binding var showError: Bool
    let onPINEntered: (String) -> Void

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Text("Enter PIN")
                .font(.largeTitle)
                .fontWeight(.bold)

            // PIN表示部分
            HStack(spacing: 20) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index < pinInput.count ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 20, height: 20)
                }
            }

            if showError {
                Text("Incorrect PIN")
                    .foregroundColor(.red)
                    .font(.headline)
            }

            Spacer()

            // 数字パッド
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                ForEach(1...9, id: \.self) { number in
                    Button(action: {
                        addDigit("\(number)")
                    }) {
                        Text("\(number)")
                            .font(.title)
                            .frame(width: 80, height: 80)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // 空のスペース
                Color.clear
                    .frame(width: 80, height: 80)

                // 0ボタン
                Button(action: {
                    addDigit("0")
                }) {
                    Text("0")
                        .font(.title)
                        .frame(width: 80, height: 80)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())

                // 削除ボタン
                Button(action: {
                    deleteDigit()
                }) {
                    Image(systemName: "delete.left")
                        .font(.title)
                        .frame(width: 80, height: 80)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }

            Spacer()
        }
        .padding()
        .background(Color.black)
        .foregroundColor(.white)
    }

    private func addDigit(_ digit: String) {
        if pinInput.count < 4 {
            pinInput += digit
            if pinInput.count == 4 {
                onPINEntered(pinInput)
            }
        }
    }

    private func deleteDigit() {
        if !pinInput.isEmpty {
            pinInput.removeLast()
        }
    }
}

#Preview {
    ContentView()
}
