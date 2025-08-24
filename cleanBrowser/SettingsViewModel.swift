import Foundation
import Combine

final class SettingsViewModel: ObservableObject {
    @Published var confirmNavigation: Bool
    @Published var customKeyboardEnabled: Bool
    @Published var soundDetectionEnabled: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private let tabManager = TabManager.shared

    init() {
        // 初期値を TabManager から読み込む
        self.confirmNavigation = tabManager.confirmNavigation
        self.customKeyboardEnabled = tabManager.customKeyboardEnabled

        // TabManager の変更を監視して同期
        tabManager.$confirmNavigation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] v in self?.confirmNavigation = v }
            .store(in: &cancellables)

        tabManager.$customKeyboardEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] v in self?.customKeyboardEnabled = v }
            .store(in: &cancellables)

        // soundDetection は TabManager に無いので UserDefaults を使う
        if UserDefaults.standard.object(forKey: "SoundDetectionEnabled") != nil {
            self.soundDetectionEnabled = UserDefaults.standard.bool(forKey: "SoundDetectionEnabled")
        }

        // ViewModel の変更を TabManager に反映
        $confirmNavigation
            .dropFirst()
            .sink { [weak self] v in self?.tabManager.confirmNavigation = v }
            .store(in: &cancellables)

        $customKeyboardEnabled
            .dropFirst()
            .sink { [weak self] v in self?.tabManager.customKeyboardEnabled = v }
            .store(in: &cancellables)

        $soundDetectionEnabled
            .dropFirst()
            .sink { v in
                UserDefaults.standard.set(v, forKey: "SoundDetectionEnabled")
                if v { SoundDetector.shared.startIfNeeded() } else { SoundDetector.shared.stop() }
            }
            .store(in: &cancellables)
    }
}
