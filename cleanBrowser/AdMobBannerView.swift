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
    // Google のテスト用バナー広告ユニットID
    
    //テスト
//    static let testBannerUnitId = "ca-app-pub-3940256099942544/2934735716"
    
    
    //本番
    static let testBannerUnitId = "ca-app-pub-7782777506427620/9898233758"

}

struct AdMobBannerView: UIViewRepresentable {
    let adUnitID: String
    @EnvironmentObject var attManager: ATTManager
    
    // 既定値：Info.plist の BrowserFootAdBarId（なければテスト用バナーID）
    init(adUnitID: String = {
        let v = AdsConfig.footerBanner.trimmingCharacters(in: .whitespacesAndNewlines)
        return v.isEmpty ? AdsConfig.testBannerUnitId : v
    }()) {
        self.adUnitID = adUnitID
    }
    
    func makeUIView(context: Context) -> BannerView {
        // 320x50 の標準バナー（必要に応じて Adaptive に変更可能）
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID
        
        // rootViewController をできるだけ安全に取得
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
           let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first {
            bannerView.rootViewController = window.rootViewController
        }
        
        let request = Request()
        
        // ATT の許可状況に応じて広告リクエストを設定
        if !attManager.canShowPersonalizedAds {
            let extras = Extras()
            extras.additionalParameters = ["npa": "1"]
            request.register(extras)
        }
        
        bannerView.load(request)
        return bannerView
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {
        // ATT ステータスが変更された場合など、広告を再読み込み
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
