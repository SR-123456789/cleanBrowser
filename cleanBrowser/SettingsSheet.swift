import SwiftUI

// 設定シートを独立ファイルに分離
struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = SettingsViewModel()
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
                        Toggle(isOn: $vm.confirmNavigation) {
                            Text("URL移動前に確認")
                        }
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.secondary)
                            .help("新しいURLへ移動する前に確認アラートを表示します")
                    }
                }
                Section(header: Text("キーボード")) {
                    HStack {
                        Toggle(isOn: $vm.customKeyboardEnabled) {
                            Text("独自キーボードを有効にする")
                        }
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.secondary)
                            .help("サイトの入力時に独自のキーボードを使用します")
                    }
                }
                Section(header: Text("足音検知")) {
                    HStack {
                        Toggle(isOn: $vm.soundDetectionEnabled) {
                            Text("足音検知を有効にする")
                        }
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.secondary)
                            .help("足音や話し声を検知したらアラートで知らせます")
                    }
                    // dB閾値のスライダー
                    VStack(alignment: .leading) {
                        HStack {
                            Text("検知閾値 (dB)")
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(String(format: "%d dB", Int(vm.dbThreshold)))
                                    .foregroundColor(.secondary)
                                Text(vm.liveDb != nil ? String(format: "現在: %.1f dB", vm.liveDb!) : "現在: -")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Slider(value: Binding(get: { Double(vm.dbThreshold) }, set: { vm.dbThreshold = Float($0) }), in: Double(-60)...Double(-10), step: 1)
                            .disabled(!vm.soundDetectionEnabled)
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
