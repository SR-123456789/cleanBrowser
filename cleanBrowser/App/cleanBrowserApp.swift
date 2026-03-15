import SwiftUI

@main
struct cleanBrowserApp: App {
    @StateObject private var attManager = ATTManager()
    @StateObject private var browserStore: BrowserStore
    @StateObject private var soundDetector: SoundDetector

    private let pinService: any PINManaging
    private let analyticsManager: any AnalyticsTracking

    init() {
        let browserStore = BrowserStore()
        let soundDetector = SoundDetector()
        let pinService = UserDefaultsPINService()
        let analyticsManager = AnalyticsManager()

        _browserStore = StateObject(wrappedValue: browserStore)
        _soundDetector = StateObject(wrappedValue: soundDetector)
        self.pinService = pinService
        self.analyticsManager = analyticsManager
        analyticsManager.trackAppOpened()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                browserStore: browserStore,
                soundDetector: soundDetector,
                pinService: pinService,
                analyticsManager: analyticsManager
            )
                .environmentObject(attManager)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        attManager.showATTDialogIfNeeded()
                    }
                }
        }
    }
}
