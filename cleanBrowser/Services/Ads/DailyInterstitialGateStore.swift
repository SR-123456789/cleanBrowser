import Foundation

struct DailyInterstitialGateState: Equatable {
    static let tapThreshold = 10

    let dayKey: String
    var tapCount: Int
    var lastCompletedDayKey: String?

    var hasCompletedToday: Bool {
        lastCompletedDayKey == dayKey
    }

    var hasReachedThreshold: Bool {
        !hasCompletedToday && tapCount >= Self.tapThreshold
    }
}

@MainActor
protocol DailyInterstitialGateStoring {
    func currentState() -> DailyInterstitialGateState
    @discardableResult
    func recordTap() -> DailyInterstitialGateState
    @discardableResult
    func markCompleted() -> DailyInterstitialGateState
}

@MainActor
final class UserDefaultsDailyInterstitialGateStore: DailyInterstitialGateStoring {
    private enum Keys {
        static let tapDayKey = "daily_interstitial.tap_day"
        static let tapCount = "daily_interstitial.tap_count"
        static let completedDayKey = "daily_interstitial.completed_day"
    }

    private let defaults: UserDefaults
    private var calendar: Calendar
    private let nowProvider: () -> Date

    init(
        defaults: UserDefaults = .standard,
        calendar: Calendar = .current,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.defaults = defaults
        self.calendar = calendar
        self.nowProvider = nowProvider
    }

    func currentState() -> DailyInterstitialGateState {
        state(for: nowProvider())
    }

    func recordTap() -> DailyInterstitialGateState {
        var state = currentState()
        guard !state.hasCompletedToday, !state.hasReachedThreshold else { return state }

        state.tapCount += 1
        persist(state)
        return state
    }

    func markCompleted() -> DailyInterstitialGateState {
        var state = currentState()
        state.lastCompletedDayKey = state.dayKey
        persist(state)
        return state
    }

    private func state(for now: Date) -> DailyInterstitialGateState {
        let todayKey = dayKey(for: now)
        let storedTapDayKey = defaults.string(forKey: Keys.tapDayKey)
        let tapCount = storedTapDayKey == todayKey ? defaults.integer(forKey: Keys.tapCount) : 0

        return DailyInterstitialGateState(
            dayKey: todayKey,
            tapCount: tapCount,
            lastCompletedDayKey: defaults.string(forKey: Keys.completedDayKey)
        )
    }

    private func persist(_ state: DailyInterstitialGateState) {
        defaults.set(state.dayKey, forKey: Keys.tapDayKey)
        defaults.set(state.tapCount, forKey: Keys.tapCount)

        if let lastCompletedDayKey = state.lastCompletedDayKey {
            defaults.set(lastCompletedDayKey, forKey: Keys.completedDayKey)
        } else {
            defaults.removeObject(forKey: Keys.completedDayKey)
        }
    }

    private func dayKey(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}
