import XCTest
@testable import cleanBrowser

@MainActor
final class DailyInterstitialGateStoreTests: XCTestCase {
    private let suiteName = "DailyInterstitialGateStoreTests"
    private var defaults: UserDefaults!
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        calendar = nil
        super.tearDown()
    }

    func test_recordTap_reachesThresholdOnTenthTap() {
        let store = makeStore(now: date("2026-03-15"))

        var latestState = store.currentState()
        for _ in 0..<DailyInterstitialGateState.tapThreshold {
            latestState = store.recordTap()
        }

        XCTAssertEqual(latestState.tapCount, DailyInterstitialGateState.tapThreshold)
        XCTAssertTrue(latestState.hasReachedThreshold)
    }

    func test_markCompleted_blocksFurtherThresholdForSameDay() {
        let store = makeStore(now: date("2026-03-15"))

        for _ in 0..<DailyInterstitialGateState.tapThreshold {
            _ = store.recordTap()
        }

        let completedState = store.markCompleted()
        let postCompletionState = store.recordTap()

        XCTAssertTrue(completedState.hasCompletedToday)
        XCTAssertEqual(postCompletionState.tapCount, DailyInterstitialGateState.tapThreshold)
        XCTAssertFalse(postCompletionState.hasReachedThreshold)
    }

    func test_recordTap_doesNotExceedThresholdAfterTenthTap() {
        let store = makeStore(now: date("2026-03-15"))

        for _ in 0..<DailyInterstitialGateState.tapThreshold {
            _ = store.recordTap()
        }

        let stateAfterExtraTap = store.recordTap()

        XCTAssertEqual(stateAfterExtraTap.tapCount, DailyInterstitialGateState.tapThreshold)
        XCTAssertTrue(stateAfterExtraTap.hasReachedThreshold)
    }

    func test_currentState_resetsTapCountWhenStoredDayIsDifferent() {
        defaults.set("2026-03-14", forKey: "daily_interstitial.tap_day")
        defaults.set(9, forKey: "daily_interstitial.tap_count")

        let store = makeStore(now: date("2026-03-15"))
        let state = store.currentState()

        XCTAssertEqual(state.tapCount, 0)
        XCTAssertEqual(state.dayKey, "2026-03-15")
    }

    func test_dayRollover_allowsThresholdAgainOnNextDay() {
        var now = date("2026-03-15")
        let store = UserDefaultsDailyInterstitialGateStore(
            defaults: defaults,
            calendar: calendar,
            nowProvider: { now }
        )

        for _ in 0..<DailyInterstitialGateState.tapThreshold {
            _ = store.recordTap()
        }
        _ = store.markCompleted()

        now = date("2026-03-16")

        XCTAssertFalse(store.currentState().hasCompletedToday)
        XCTAssertEqual(store.currentState().tapCount, 0)

        var nextDayState = store.currentState()
        for _ in 0..<DailyInterstitialGateState.tapThreshold {
            nextDayState = store.recordTap()
        }

        XCTAssertEqual(nextDayState.dayKey, "2026-03-16")
        XCTAssertTrue(nextDayState.hasReachedThreshold)
    }

    private func makeStore(now: Date) -> UserDefaultsDailyInterstitialGateStore {
        UserDefaultsDailyInterstitialGateStore(
            defaults: defaults,
            calendar: calendar,
            nowProvider: { now }
        )
    }

    private func date(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)!
    }
}
