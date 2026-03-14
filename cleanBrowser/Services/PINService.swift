import Foundation

protocol PINManaging {
    var isFirstLaunch: Bool { get }
    var hasPINSet: Bool { get }

    func verifyPIN(_ pin: String) -> Bool
    func updatePIN(_ newPIN: String)
}

final class UserDefaultsPINService: PINManaging {
    private let userDefaults: UserDefaults
    private let pinKey = "UserPIN"
    private let isFirstLaunchKey = "IsFirstLaunch"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var isFirstLaunch: Bool {
        !userDefaults.bool(forKey: isFirstLaunchKey)
    }

    private var currentPIN: String? {
        userDefaults.string(forKey: pinKey)
    }

    var hasPINSet: Bool {
        currentPIN != nil
    }

    func verifyPIN(_ pin: String) -> Bool {
        guard let currentPIN else { return false }
        return pin == currentPIN
    }

    func updatePIN(_ newPIN: String) {
        userDefaults.set(newPIN, forKey: pinKey)
        if isFirstLaunch {
            userDefaults.set(true, forKey: isFirstLaunchKey)
        }
    }
}
