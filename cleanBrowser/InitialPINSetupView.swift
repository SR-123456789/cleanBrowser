import SwiftUI

struct InitialPINSetupView: View {
    @State private var newPIN = ""
    @State private var confirmPIN = ""
    @State private var showNewPINEntry = true
    @State private var showConfirmPINEntry = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    let onPINSet: () -> Void
    private let pinManager = PINManager.shared
    var body: some View {
        VStack {
            Spacer() // 上余白
            
            if showNewPINEntry {
                CompactPINEntrySection(
                    title: "PIN設定",
                    pinInput: $newPIN,
                    showError: $showError,
                    errorMessage: errorMessage,
                    onPINEntered: { pin in
                        showNewPINEntry = false
                        showConfirmPINEntry = true
                    }
                )
            } else if showConfirmPINEntry {
                CompactPINEntrySection(
                    title: "もう一度入力",
                    pinInput: $confirmPIN,
                    showError: $showError,
                    errorMessage: errorMessage,
                    onPINEntered: { pin in
                        if pin == newPIN {
                            pinManager.updatePIN(pin)
                            onPINSet()
                        } else {
                            showError = true
                            errorMessage = "PINが一致しません"
                            confirmPIN = ""
                            newPIN = ""
                            showConfirmPINEntry = false
                            showNewPINEntry = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showError = false
                            }
                        }
                    }
                )
            }
            
            Spacer() // 下余白
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .ignoresSafeArea()
    }
}
struct CompactPINEntrySection: View {
    let title: String
    @Binding var pinInput: String
    @Binding var showError: Bool
    let errorMessage: String
    let onPINEntered: (String) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // PIN表示部分
            HStack(spacing: 20) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index < pinInput.count ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 20, height: 20)
                }
            }
            
            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }
            
            // 数字パッド (サイズを小さく)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                ForEach(1...9, id: \.self) { number in
                    Button(action: {
                        addDigit("\(number)")
                    }) {
                        Text("\(number)")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 70, height: 70)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // 空のスペース
                Color.clear
                    .frame(width: 70, height: 70)
                
                // 0ボタン
                Button(action: {
                    addDigit("0")
                }) {
                    Text("0")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 70, height: 70)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                
                // 削除ボタン
                Button(action: {
                    deleteDigit()
                }) {
                    Image(systemName: "delete.left")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 70, height: 70)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
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
    InitialPINSetupView(onPINSet: {})
}
