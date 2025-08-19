//
//  AdMobBannerView.swift
//  cleanBrowser
//
//  Created by NakataniSoshi on 2025/08/10.
//

import SwiftUI
import UIKit
import GoogleMobileAds

// このファイル内だけで使うヘルパー
private enum AdsConfig {
    static func info(_ key: String) -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String ?? ""
    }
    static var footerBanner: String { info("BrowserFootAdBarId") }
    static let testBanner = "ca-app-pub-7782777506427620~5964742075"
}

struct AdMobBannerView: UIViewRepresentable {
    let adUnitID: String
    @EnvironmentObject var attManager: ATTManager
    
    // 既定値：Info.plist の BrowserFootAdBarId（なければテストID）
    init(adUnitID: String = {
        let v = AdsConfig.footerBanner.trimmingCharacters(in: .whitespacesAndNewlines)
        return v.isEmpty ? AdsConfig.testBanner : v
    }()) {
        self.adUnitID = adUnitID
    }
    
    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner) // 320x50の標準バナー
        bannerView.adUnitID = adUnitID
        
        // rootViewControllerをできるだけ安全に取得
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
           let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first {
            bannerView.rootViewController = window.rootViewController
        }
        
        let request = Request()
        
        // ATTの許可状況に応じて広告リクエストを設定
        if !attManager.canShowPersonalizedAds {
            // パーソナライズされていない広告をリクエスト
            let extras = Extras()
            extras.additionalParameters = ["npa": "1"]
            request.register(extras)
        }
        
        bannerView.load(request)
        return bannerView
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {
        // ATTステータスが変更された場合、広告を再読み込み
        let request = Request()
        
        if !attManager.canShowPersonalizedAds {
            let extras = Extras()
            extras.additionalParameters = ["npa": "1"]
            request.register(extras)
        }
        
        uiView.load(request)
    }
}

#Preview {
    AdMobBannerView()
        .frame(height: 50)
        .environmentObject(ATTManager())
}
