import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var confirmNavigation: Bool
    @Published var customKeyboardEnabled: Bool
    @Published var soundDetectionEnabled: Bool
    @Published var dbThreshold: Float
    @Published var liveDb: Float?

    private var cancellables = Set<AnyCancellable>()
    private let browserStore: BrowserStore
    private let soundDetector: SoundDetector

    init(browserStore: BrowserStore, soundDetector: SoundDetector) {
        self.browserStore = browserStore
        self.soundDetector = soundDetector
        self.confirmNavigation = browserStore.confirmNavigation
        self.customKeyboardEnabled = browserStore.customKeyboardEnabled
        self.soundDetectionEnabled = soundDetector.isEnabled
        self.dbThreshold = soundDetector.dbThreshold
        self.liveDb = soundDetector.liveDb

        browserStore.$confirmNavigation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] v in self?.confirmNavigation = v }
            .store(in: &cancellables)

        browserStore.$customKeyboardEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] v in self?.customKeyboardEnabled = v }
            .store(in: &cancellables)

        soundDetector.$isEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in self?.soundDetectionEnabled = isEnabled }
            .store(in: &cancellables)

        soundDetector.$dbThreshold
            .receive(on: DispatchQueue.main)
            .sink { [weak self] threshold in self?.dbThreshold = threshold }
            .store(in: &cancellables)

        soundDetector.$liveDb
            .receive(on: DispatchQueue.main)
            .sink { [weak self] db in self?.liveDb = db }
            .store(in: &cancellables)

        $confirmNavigation
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] value in
                self?.browserStore.confirmNavigation = value
            }
            .store(in: &cancellables)

        $customKeyboardEnabled
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] value in
                self?.browserStore.customKeyboardEnabled = value
            }
            .store(in: &cancellables)

        $soundDetectionEnabled
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                self?.soundDetector.setEnabled(isEnabled)
            }
            .store(in: &cancellables)

        $dbThreshold
            .dropFirst()
            .sink { [weak self] threshold in
                self?.soundDetector.setDbThreshold(threshold)
            }
            .store(in: &cancellables)
    }
}
