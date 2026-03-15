import XCTest
@testable import cleanBrowser

final class PINServiceTests: XCTestCase {
    private let suiteName = "PINServiceTests"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func test_initialState_isFirstLaunchAndHasNoPIN() {
        let service = UserDefaultsPINService(userDefaults: defaults)

        XCTAssertTrue(service.isFirstLaunch)
        XCTAssertFalse(service.hasPINSet)
        XCTAssertFalse(service.verifyPIN("1234"))
    }

    func test_updatePIN_persistsPINAndClearsFirstLaunch() {
        let service = UserDefaultsPINService(userDefaults: defaults)

        service.updatePIN("1234")

        XCTAssertFalse(service.isFirstLaunch)
        XCTAssertTrue(service.hasPINSet)
        XCTAssertTrue(service.verifyPIN("1234"))
    }

    func test_verifyPIN_returnsFalseForWrongPIN() {
        let service = UserDefaultsPINService(userDefaults: defaults)
        service.updatePIN("1234")

        XCTAssertFalse(service.verifyPIN("9999"))
    }

    func test_existingPINIsLoadedFromDefaults() {
        defaults.set("2468", forKey: "UserPIN")
        defaults.set(true, forKey: "IsFirstLaunch")

        let service = UserDefaultsPINService(userDefaults: defaults)

        XCTAssertFalse(service.isFirstLaunch)
        XCTAssertTrue(service.hasPINSet)
        XCTAssertTrue(service.verifyPIN("2468"))
    }
}
