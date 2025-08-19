import SwiftUI

@main
struct cleanBrowserApp: App {
    @StateObject private var attManager = ATTManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(attManager)
                .onAppear {
                    // アプリ起動時にATTダイアログを表示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        attManager.showATTDialogIfNeeded()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        // 既存の黒い画面があれば削除
                        window.viewWithTag(999)?.removeFromSuperview()
                        
                        let blackoutView = UIView(frame: window.bounds)
                        blackoutView.backgroundColor = .black
                        blackoutView.tag = 999
                        
                        // 最前面に追加
                        window.addSubview(blackoutView)
                        window.bringSubviewToFront(blackoutView)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        // 黒い画面を削除
                        window.viewWithTag(999)?.removeFromSuperview()
                        
                        // ContentViewをPIN入力画面にリセット
                        NotificationCenter.default.post(name: NSNotification.Name("ResetToPIN"), object: nil)
                    }
                }
        }
    }
}
