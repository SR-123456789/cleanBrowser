//
//  ATTManager.swift
//  cleanBrowser
//
//  Created by NakataniSoshi on 2025/08/19.
//

import SwiftUI
import AppTrackingTransparency
import AdSupport

class ATTManager: ObservableObject {
    @Published var trackingStatus: ATTrackingManager.AuthorizationStatus = .notDetermined
    
    init() {
        trackingStatus = ATTrackingManager.trackingAuthorizationStatus
    }
    
    func requestPermission() {
        ATTrackingManager.requestTrackingAuthorization { status in
            DispatchQueue.main.async {
                self.trackingStatus = status
                switch status {
                case .authorized:
                    print("ATT: 許可されました")
                case .denied:
                    print("ATT: 拒否されました")
                case .restricted:
                    print("ATT: 制限されています")
                case .notDetermined:
                    print("ATT: 未決定です")
                @unknown default:
                    print("ATT: 不明なステータスです")
                }
            }
        }
    }
    
    var canShowPersonalizedAds: Bool {
        return trackingStatus == .authorized
    }
    
    func showATTDialogIfNeeded() {
        if trackingStatus == .notDetermined {
            // iOS 14.5以降でのみATTダイアログを表示
            if #available(iOS 14.5, *) {
                requestPermission()
            }
        }
    }
}