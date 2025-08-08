import Foundation

class PINManager {
    static let shared = PINManager()
    
    private let userDefaults = UserDefaults.standard
    private let pinKey = "UserPIN"
    private let isFirstLaunchKey = "IsFirstLaunch"
    
    private init() {}
    
    var isFirstLaunch: Bool {
        return !userDefaults.bool(forKey: isFirstLaunchKey)
    }
    
    var currentPIN: String? {
        return userDefaults.string(forKey: pinKey)
    }
    
    var hasPINSet: Bool {
        return currentPIN != nil
    }
    
    func verifyPIN(_ pin: String) -> Bool {
        guard let currentPIN = currentPIN else { return false }
        return pin == currentPIN
    }
    
    func updatePIN(_ newPIN: String) {
        userDefaults.set(newPIN, forKey: pinKey)
        if isFirstLaunch {
            userDefaults.set(true, forKey: isFirstLaunchKey)
        }
    }
}
