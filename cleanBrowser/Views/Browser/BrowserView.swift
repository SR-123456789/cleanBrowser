import SwiftUI

struct BrowserView: View {
    @EnvironmentObject private var attManager: ATTManager
    @StateObject private var viewModel: BrowserViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    @StateObject private var tabOverviewViewModel: TabOverviewViewModel
    @StateObject private var dailyInterstitialGateViewModel = DailyInterstitialGateViewModel()
    private let pinService: any PINManaging

    init(browserStore: BrowserStore, soundDetector: SoundDetector, pinService: any PINManaging) {
        self.pinService = pinService
        _viewModel = StateObject(wrappedValue: BrowserViewModel(browserStore: browserStore))
        _settingsViewModel = StateObject(
            wrappedValue: SettingsViewModel(browserStore: browserStore, soundDetector: soundDetector)
        )
        _tabOverviewViewModel = StateObject(wrappedValue: TabOverviewViewModel(browserStore: browserStore))
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
                        onKeyboardVisibilityChanged: viewModel.setKeyboardVisible
                    )
                    .id(activeTab.id)
                    .ignoresSafeArea(.keyboard)
                }

                if viewModel.shouldShowCustomKeyboard {
                    CustomKeyboard(
                        webView: viewModel.activeTab?.webView,
                        isKeyboardVisible: $viewModel.isKeyboardVisible
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .background {
                if !dailyInterstitialGateViewModel.isAdPresenting {
                    WindowTapSpyView {
                        guard !viewModel.isModalPresented else { return }
                        dailyInterstitialGateViewModel.recordScreenTap()
                    }
                    .frame(width: 0, height: 0)
                }
            }
            .allowsHitTesting(!dailyInterstitialGateViewModel.isBlockingUI)

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
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isKeyboardVisible)
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
            dailyInterstitialGateViewModel.prepareIfNeeded(
                canShowPersonalizedAds: attManager.canShowPersonalizedAds
            )
        }
        .onChange(of: attManager.canShowPersonalizedAds) { _, canShowPersonalizedAds in
            dailyInterstitialGateViewModel.prepareIfNeeded(
                canShowPersonalizedAds: canShowPersonalizedAds
            )
        }
        .onChange(of: dailyInterstitialGateViewModel.isBlockingUI) { _, isBlockingUI in
            if isBlockingUI {
                viewModel.isKeyboardVisible = false
            }
        }
    }
}

#Preview {
    NavigationView {
        BrowserView(
            browserStore: BrowserStore(),
            soundDetector: SoundDetector(),
            pinService: UserDefaultsPINService()
        )
    }
    .environmentObject(ATTManager())
}
