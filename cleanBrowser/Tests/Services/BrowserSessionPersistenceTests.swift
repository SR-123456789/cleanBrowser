import XCTest
@testable import cleanBrowser

final class BrowserSessionPersistenceTests: XCTestCase {
    private let suiteName = "BrowserSessionPersistenceTests"
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

    func test_load_returnsDefaultStateWhenNothingPersisted() {
        let persistence = UserDefaultsBrowserSessionPersistence(userDefaults: defaults)

        XCTAssertEqual(
            persistence.load(),
            BrowserSessionState(
                tabs: [],
                activeTabIndex: 0,
                confirmNavigation: true,
                isMutedGlobal: false,
                customKeyboardEnabled: true
            )
        )
    }

    func test_load_preservesExplicitlyDisabledCustomKeyboardSetting() {
        defaults.set(false, forKey: "CustomKeyboardEnabled")
        let persistence = UserDefaultsBrowserSessionPersistence(userDefaults: defaults)

        XCTAssertFalse(persistence.load().customKeyboardEnabled)
    }

    func test_saveAndLoad_roundTripSessionState() {
        let persistence = UserDefaultsBrowserSessionPersistence(userDefaults: defaults)
        let state = BrowserSessionState(
            tabs: [
                .init(url: "https://example.com", title: "Example"),
                .init(url: "https://openai.com", title: "OpenAI"),
            ],
            activeTabIndex: 1,
            confirmNavigation: false,
            isMutedGlobal: true,
            customKeyboardEnabled: true
        )

        persistence.save(state)

        XCTAssertEqual(persistence.load(), state)
    }

    func test_load_ignoresMalformedTabRecords() {
        defaults.set(
            [
                ["url": "https://example.com", "title": "Example"],
                ["url": "missing title"],
                ["title": "missing url"],
            ],
            forKey: "SavedTabs"
        )

        let persistence = UserDefaultsBrowserSessionPersistence(userDefaults: defaults)
        let state = persistence.load()

        XCTAssertEqual(
            state.tabs,
            [.init(url: "https://example.com", title: "Example")]
        )
    }
}
