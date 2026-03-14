import SwiftUI
import GoogleMobileAds

struct BrowserView: View {
    @StateObject private var viewModel: BrowserViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    @StateObject private var tabOverviewViewModel: TabOverviewViewModel
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

            AdMobBannerView()
                .frame(height: 50)
                .background(Color(.systemBackground))
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
}
