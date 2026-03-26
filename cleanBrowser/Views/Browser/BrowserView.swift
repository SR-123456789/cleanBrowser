import SwiftUI

struct BrowserView: View {
    @EnvironmentObject private var attManager: ATTManager
    @StateObject private var viewModel: BrowserViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    @StateObject private var tabOverviewViewModel: TabOverviewViewModel
    @StateObject private var dailyInterstitialGateViewModel: DailyInterstitialGateViewModel
    @State private var pendingSoundDetectorResumeTask: Task<Void, Never>?
    private let pinService: any PINManaging
    private let soundDetector: SoundDetector

    init(
        browserStore: BrowserStore,
        soundDetector: SoundDetector,
        pinService: any PINManaging,
        analyticsManager: any AnalyticsTracking
    ) {
        self.pinService = pinService
        self.soundDetector = soundDetector
        _viewModel = StateObject(
            wrappedValue: BrowserViewModel(browserStore: browserStore, analytics: analyticsManager)
        )
        _settingsViewModel = StateObject(
            wrappedValue: SettingsViewModel(browserStore: browserStore, soundDetector: soundDetector)
        )
        _tabOverviewViewModel = StateObject(wrappedValue: TabOverviewViewModel(browserStore: browserStore))
        _dailyInterstitialGateViewModel = StateObject(
            wrappedValue: DailyInterstitialGateViewModel(analytics: analyticsManager)
        )
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if let activeTab = viewModel.activeTab {
                    BrowserToolbar(
                        currentURL: activeTab.url,
                        canGoBack: activeTab.canGoBack,
                        canGoForward: activeTab.canGoForward,
                        isLoading: activeTab.isLoading,
                        isMutedGlobal: viewModel.isMutedGlobal,
                        tabCount: viewModel.tabCount,
                        onGoBack: viewModel.goBack,
                        onGoForward: viewModel.goForward,
                        onBeginAddressEditing: viewModel.beginAddressEditing,
                        onSubmitAddress: viewModel.navigate,
                        onToggleMute: viewModel.toggleMute,
                        onShowSettings: { viewModel.showSettingsSheet = true },
                        onShowTabs: { viewModel.showTabOverview.toggle() }
                    )
                }

                if let activeTab = viewModel.activeTab {
                    WebViewRepresentable(
                        tab: activeTab,
                        browserStore: viewModel.browserStore,
                        onInputStateChanged: viewModel.handleWebInputStateChange,
                        onSystemKeyboardGuideRequested: viewModel.handleSystemKeyboardGuideRequested
                    )
                    .id(activeTab.id)
                    .ignoresSafeArea(.keyboard)
                }

                if viewModel.shouldShowCustomKeyboard {
                    CustomKeyboard(
                        webView: viewModel.activeTab?.webView,
                        isKeyboardVisible: $viewModel.isKeyboardVisible,
                        onDismiss: viewModel.dismissCustomKeyboard,
                        onSwitchToSystemKeyboard: viewModel.switchToSystemKeyboard
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .opacity(dailyInterstitialGateViewModel.isAdPresenting ? 0.01 : 1)
            .allowsHitTesting(!dailyInterstitialGateViewModel.isAdPresenting)
            .background {
                WindowTapSpyView(
                    isEnabled: dailyInterstitialGateViewModel.shouldTrackScreenTaps
                ) {
                    guard !viewModel.isModalPresented else { return }
                    dailyInterstitialGateViewModel.recordScreenTap()
                }
                .frame(width: 0, height: 0)
            }

            if dailyInterstitialGateViewModel.isGatePresented {
                DailyInterstitialGateOverlay(
                    title: dailyInterstitialGateViewModel.titleText,
                    description: dailyInterstitialGateViewModel.descriptionText,
                    detail: dailyInterstitialGateViewModel.detailText,
                    buttonTitle: dailyInterstitialGateViewModel.primaryButtonTitle,
                    isButtonEnabled: dailyInterstitialGateViewModel.isPrimaryButtonEnabled,
                    isLoading: dailyInterstitialGateViewModel.isLoadingAd,
                    onPrimaryAction: dailyInterstitialGateViewModel.presentAd
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if viewModel.showCustomKeyboardGuide {
                Color.black.opacity(0.18)
                    .ignoresSafeArea()
                    .transition(.opacity)

                VStack {
                    Spacer()

                    CustomKeyboardGuideCard(
                        onEnable: viewModel.enableCustomKeyboardFromGuide,
                        onDismiss: viewModel.dismissCustomKeyboardGuide
                    )
                    .padding(.horizontal, 14)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isKeyboardVisible)
        .animation(.spring(response: 0.36, dampingFraction: 0.9), value: viewModel.showCustomKeyboardGuide)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(viewModel.navigationTitle)
        .navigationBarHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("キーボード") {
                    viewModel.toggleKeyboard()
                }
                .disabled(!viewModel.browserStore.customKeyboardEnabled)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button("設定") { viewModel.showSettingsSheet = true }
            }
        }
        .sheet(isPresented: $viewModel.showTabOverview) {
            TabOverviewView(viewModel: tabOverviewViewModel, isPresented: $viewModel.showTabOverview)
        }
        .sheet(isPresented: $viewModel.showPINSettings) { PINSettingsView(pinService: pinService) }
        .sheet(isPresented: $viewModel.showSettingsSheet) {
            SettingsSheet(viewModel: settingsViewModel, showPINSettings: $viewModel.showPINSettings)
        }
        .onAppear {
            dailyInterstitialGateViewModel.setStartupVisibility(viewModel.browserStore.isDailyInterstitialVisible)
            dailyInterstitialGateViewModel.prepareIfNeeded(
                canShowPersonalizedAds: attManager.canShowPersonalizedAds
            )
            viewModel.handleModalPresentationChanged()
        }
        .onChange(of: viewModel.browserStore.isDailyInterstitialVisible) { _, isVisible in
            dailyInterstitialGateViewModel.setStartupVisibility(isVisible)
            dailyInterstitialGateViewModel.prepareIfNeeded(
                canShowPersonalizedAds: attManager.canShowPersonalizedAds
            )
        }
        .onChange(of: attManager.canShowPersonalizedAds) { _, canShowPersonalizedAds in
            dailyInterstitialGateViewModel.prepareIfNeeded(
                canShowPersonalizedAds: canShowPersonalizedAds
            )
        }
        .onChange(of: dailyInterstitialGateViewModel.isAdPresenting) { _, isAdPresenting in
            pendingSoundDetectorResumeTask?.cancel()
            viewModel.handleInterstitialPresentationChanged(isAdPresenting)

            if isAdPresenting {
                soundDetector.suspendTemporarily()
            } else {
                pendingSoundDetectorResumeTask = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(450))
                    guard !Task.isCancelled else { return }
                    soundDetector.resumeTemporarily()
                }
            }
        }
        .onDisappear {
            pendingSoundDetectorResumeTask?.cancel()
            viewModel.handleInterstitialPresentationChanged(false)
        }
        .onChange(of: viewModel.isModalPresented) { _, _ in
            viewModel.handleModalPresentationChanged()
        }
    }
}

#Preview {
    NavigationView {
        BrowserView(
            browserStore: BrowserStore(),
            soundDetector: SoundDetector(),
            pinService: UserDefaultsPINService(),
            analyticsManager: NoopAnalyticsManager()
        )
    }
    .environmentObject(ATTManager())
}
