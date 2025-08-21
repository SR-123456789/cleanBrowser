import SwiftUI

struct ContentView: View {
    @State private var isUnlocked = false
    @State private var pinInput = ""
    @State private var showError = false
    @State private var showPINSettings = false
    @State private var hasPINBeenSet = false
    
    private let pinManager = PINManager.shared

    var body: some View {
        // 初回起動時またはPIN未設定時は初期設定画面を表示
        if (pinManager.isFirstLaunch || !pinManager.hasPINSet) && !hasPINBeenSet {
            InitialPINSetupView(onPINSet: {
                hasPINBeenSet = true
            })
        } else if isUnlocked {
            BrowserView()
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetToPIN"))) { _ in
                    // アプリ切り替え後にPIN入力画面に戻る
                    isUnlocked = false
                    pinInput = ""
                    showError = false
                }
                .ignoresSafeArea(.container, edges: .bottom) // ← 下端だけ外へ
                        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetToPIN"))) { _ in
                            isUnlocked = false
                            pinInput = ""
                            showError = false
                        }
        } else {
            PINEntryScreen(
                pinInput: $pinInput,
                showError: $showError,
                showPINSettings: $showPINSettings,
                onPINEntered: { pin in
                    if pinManager.verifyPIN(pin) {
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
            .sheet(isPresented: $showPINSettings) {
                PINSettingsView()
            }
        }

    }
    
}

struct PINEntryScreen: View {
    @Binding var pinInput: String
    @Binding var showError: Bool
    @Binding var showPINSettings: Bool
    let onPINEntered: (String) -> Void

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Text("PINを入力してください")
                .font(.system(size: 12)) // largeTitle の約1/3

            // PIN表示部分
            HStack(spacing: 20) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index < pinInput.count ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 20, height: 20)
                }
            }

            if showError {
                Text("PINが間違えています")
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
