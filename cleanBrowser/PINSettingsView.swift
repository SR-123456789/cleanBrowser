import SwiftUI

struct PINSettingsView: View {
    @State private var currentPIN = ""
    @State private var newPIN = ""
    @State private var confirmPIN = ""
    @State private var showCurrentPINEntry = true
    @State private var showNewPINEntry = false
    @State private var showConfirmPINEntry = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isCompleted = false
    @Environment(\.dismiss) private var dismiss
    
    private let pinManager = PINManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if showCurrentPINEntry {
                    PINEntrySection(
                        title: "Enter Current PIN",
                        pinInput: $currentPIN,
                        showError: $showError,
                        errorMessage: errorMessage,
                        onPINEntered: { pin in
                            if pinManager.verifyPIN(pin) {
                                showCurrentPINEntry = false
                                showNewPINEntry = true
                                showError = false
                            } else {
                                showError = true
                                errorMessage = "Incorrect current PIN"
                                currentPIN = ""
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showError = false
                                }
                            }
                        }
                    )
                } else if showNewPINEntry {
                    PINEntrySection(
                        title: "Enter New PIN",
                        pinInput: $newPIN,
                        showError: $showError,
                        errorMessage: errorMessage,
                        onPINEntered: { pin in
                            showNewPINEntry = false
                            showConfirmPINEntry = true
                        }
                    )
                } else if showConfirmPINEntry {
                    PINEntrySection(
                        title: "Confirm New PIN",
                        pinInput: $confirmPIN,
                        showError: $showError,
                        errorMessage: errorMessage,
                        onPINEntered: { pin in
                            if pin == newPIN {
                                pinManager.updatePIN(pin)
                                isCompleted = true
                                dismiss()
                            } else {
                                showError = true
                                errorMessage = "PINs do not match"
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
            }
            .background(Color.black)
            .navigationTitle("Change PIN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct PINEntrySection: View {
    let title: String
    @Binding var pinInput: String
    @Binding var showError: Bool
    let errorMessage: String
    let onPINEntered: (String) -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text(title)
                .font(.largeTitle)
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
                            .foregroundColor(.white)
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
                        .foregroundColor(.white)
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
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
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
    PINSettingsView()
}
