import SwiftUI

// 設定シートを独立ファイルに分離
struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var tabManager = TabManager.shared
    @Binding var showPINSettings: Bool

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("セキュリティ")) {
                    HStack {
                        Button("PINを再設定") { showPINSettings = true }
                        Spacer()
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.secondary)
                            .help("アプリ起動時のPINロックを再設定します")
                    }
                }

                Section(header: Text("動作")) {
                    HStack {
                        Toggle(isOn: $tabManager.confirmNavigation) {
                            Text("URL移動前に確認")
                        }
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.secondary)
                            .help("新しいURLへ移動する前に確認アラートを表示します")
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}
