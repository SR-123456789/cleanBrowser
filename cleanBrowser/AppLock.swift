//
//  AppLock.swift
//  cleanBrowser
//
//  Created by NakataniSoshi on 2025/08/08.
//

import SwiftUI
import Combine

final class AppLock: ObservableObject {
    @Published var isLocked: Bool = true   // 起動時もロック
    let correctPIN = "1234"                // ←あとでKeychainに

    func lock() { isLocked = true }
    func unlock(with pin: String) -> Bool {
        if pin == correctPIN {
            isLocked = false
            return true
        }
        return false
    }
}
