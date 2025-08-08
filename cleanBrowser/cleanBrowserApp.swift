//
//  cleanBrowserApp.swift
//  cleanBrowser
//
//  Created by NakataniSoshi on 2025/08/01.
//

import SwiftUI

@main
struct cleanBrowserApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    if let window = UIApplication.shared.windows.first {
                        let blackoutView = UIView(frame: window.bounds)
                        blackoutView.backgroundColor = .black
                        blackoutView.tag = 999
                        window.addSubview(blackoutView)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    if let window = UIApplication.shared.windows.first {
                        window.viewWithTag(999)?.removeFromSuperview()
                    }
                }
        }
    }
}
