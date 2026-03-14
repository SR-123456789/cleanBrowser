import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: ContentViewModel

    private let browserStore: BrowserStore
    private let soundDetector: SoundDetector
    private let pinService: any PINManaging

    init(browserStore: BrowserStore, soundDetector: SoundDetector, pinService: any PINManaging) {
        self.browserStore = browserStore
        self.soundDetector = soundDetector
        self.pinService = pinService
        _viewModel = StateObject(wrappedValue: ContentViewModel(pinService: pinService))
    }

    var body: some View {
        ZStack {
            content

            if viewModel.isPrivacyShieldVisible {
                Color.black
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            viewModel.handleScenePhase(scenePhase)
        }
        .onChange(of: scenePhase) { _, newPhase in
            viewModel.handleScenePhase(newPhase)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.shouldShowInitialSetup {
            InitialPINSetupView(pinService: pinService) {
                viewModel.onPINSet()
            }
        } else if viewModel.isUnlocked {
            BrowserView(browserStore: browserStore, soundDetector: soundDetector, pinService: pinService)
                .ignoresSafeArea(.container, edges: .bottom)
        } else {
            PINEntryScreen(viewModel: viewModel)
                .sheet(isPresented: $viewModel.showPINSettings) {
                    PINSettingsView(pinService: pinService)
                }
        }
    }
}

#Preview {
    ContentView(
        browserStore: BrowserStore(),
        soundDetector: SoundDetector(),
        pinService: UserDefaultsPINService()
    )
}
