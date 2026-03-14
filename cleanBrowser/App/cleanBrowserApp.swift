import SwiftUI

@main
struct cleanBrowserApp: App {
    @StateObject private var attManager = ATTManager()
    @StateObject private var browserStore: BrowserStore
    @StateObject private var soundDetector: SoundDetector

    private let pinService: any PINManaging

    init() {
        let browserStore = BrowserStore()
        let soundDetector = SoundDetector()
        let pinService = UserDefaultsPINService()

        _browserStore = StateObject(wrappedValue: browserStore)
        _soundDetector = StateObject(wrappedValue: soundDetector)
        self.pinService = pinService
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                browserStore: browserStore,
                soundDetector: soundDetector,
                pinService: pinService
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
