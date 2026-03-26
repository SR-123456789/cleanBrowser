import SwiftUI

struct ContentView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: ContentViewModel

    private let browserStore: BrowserStore
    private let soundDetector: SoundDetector
    private let pinService: any PINManaging
    private let analyticsManager: any AnalyticsTracking

    init(
        browserStore: BrowserStore,
        soundDetector: SoundDetector,
        pinService: any PINManaging,
        analyticsManager: any AnalyticsTracking
    ) {
        self.browserStore = browserStore
        self.soundDetector = soundDetector
        self.pinService = pinService
        self.analyticsManager = analyticsManager
        _viewModel = StateObject(
            wrappedValue: ContentViewModel(
                pinService: pinService,
                startupAdVisibilityController: browserStore
            )
        )
    }

    var body: some View {
        ZStack {
            content

            startupUpdateOverlay

            if viewModel.isPrivacyShieldVisible {
                Color.black
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            viewModel.loadStartupIfNeeded()
            viewModel.handleScenePhase(scenePhase)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                browserStore.persistCurrentSession()
            }
            if newPhase == .active {
                viewModel.loadStartupIfNeeded()
            }
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
            BrowserView(
                browserStore: browserStore,
                soundDetector: soundDetector,
                pinService: pinService,
                analyticsManager: analyticsManager
            )
                .ignoresSafeArea(.container, edges: .bottom)
        } else {
            PINEntryScreen(viewModel: viewModel)
                .sheet(isPresented: $viewModel.showPINSettings) {
                    PINSettingsView(pinService: pinService)
                }
        }
    }

    @ViewBuilder
    private var startupUpdateOverlay: some View {
        if let startupUpdatePrompt = viewModel.startupUpdatePrompt {
            StartupUpdateOverlay(
                prompt: startupUpdatePrompt,
                onPrimaryAction: {
                    handleStartupUpdatePrimaryAction(startupUpdatePrompt)
                },
                onDismiss: startupUpdatePrompt.isMandatory
                    ? nil
                    : { viewModel.dismissStartupUpdatePrompt() }
            )
        }
    }

    private func handleStartupUpdatePrimaryAction(_ prompt: StartupUpdatePrompt) {
        guard let updateURL = prompt.updateURL else { return }
        openURL(updateURL)
        if !prompt.isMandatory {
            viewModel.dismissStartupUpdatePrompt()
        }
    }
}

#Preview {
    ContentView(
        browserStore: BrowserStore(),
        soundDetector: SoundDetector(),
        pinService: UserDefaultsPINService(),
        analyticsManager: NoopAnalyticsManager()
    )
}
