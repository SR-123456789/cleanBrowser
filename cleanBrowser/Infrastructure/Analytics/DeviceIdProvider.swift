import Foundation
import UIKit

protocol DeviceIdProviding {
    func distinctId() -> String
}

struct IdentifierForVendorDeviceIdProvider: DeviceIdProviding {
    private let userDefaults: UserDefaults
    private let fallbackKey = "analytics.fallback_device_id"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func distinctId() -> String {
        if let identifierForVendor = UIDevice.current.identifierForVendor?.uuidString {
            return identifierForVendor
        }

        if let storedFallback = userDefaults.string(forKey: fallbackKey) {
            return storedFallback
        }

        let generatedFallback = UUID().uuidString
        userDefaults.set(generatedFallback, forKey: fallbackKey)
        return generatedFallback
    }
}
