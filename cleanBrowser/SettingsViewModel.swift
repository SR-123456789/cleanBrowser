import Foundation
import Combine

final class SettingsViewModel: ObservableObject {
    // Initialize published properties inline to avoid publishing during init which
    // can trigger "Publishing changes from within view updates is not allowed" warnings.
    @Published var confirmNavigation: Bool = TabManager.shared.confirmNavigation
    @Published var customKeyboardEnabled: Bool = TabManager.shared.customKeyboardEnabled
    @Published var soundDetectionEnabled: Bool = UserDefaults.standard.object(forKey: "SoundDetectionEnabled") != nil ? UserDefaults.standard.bool(forKey: "SoundDetectionEnabled") : false
    @Published var dbThreshold: Float = UserDefaults.standard.object(forKey: "SoundDetectionDbThreshold") != nil ? UserDefaults.standard.float(forKey: "SoundDetectionDbThreshold") : -30.0
    @Published var liveDb: Float? = nil

    private var cancellables = Set<AnyCancellable>()
    private let tabManager = TabManager.shared

    init() {
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
        if UserDefaults.standard.object(forKey: "SoundDetectionDbThreshold") != nil {
            self.dbThreshold = UserDefaults.standard.float(forKey: "SoundDetectionDbThreshold")
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

        // If enabled at init, start detector
        if soundDetectionEnabled { SoundDetector.shared.startIfNeeded() }

        // Listen for external changes (e.g. alert -> stop action) and sync
        NotificationCenter.default.publisher(for: Notification.Name("SoundDetectionEnabledChanged"))
            .compactMap { $0.userInfo? ["enabled"] as? NSNumber }
            .map { $0.boolValue }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] v in self?.soundDetectionEnabled = v }
            .store(in: &cancellables)

        $dbThreshold
            .dropFirst()
            .sink { v in
                UserDefaults.standard.set(v, forKey: "SoundDetectionDbThreshold")
            }
            .store(in: &cancellables)
        // Update SoundDetector cached threshold immediately when user changes it
        $dbThreshold
            .dropFirst()
            .sink { v in
                SoundDetector.shared.setDbThreshold(v)
            }
            .store(in: &cancellables)

        // Listen for live dB updates from SoundDetector
        NotificationCenter.default.publisher(for: Notification.Name("SoundDetectorDidUpdateDb"))
            .compactMap { $0.userInfo? ["db"] as? NSNumber }
            .map { $0.floatValue }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] v in self?.liveDb = v }
            .store(in: &cancellables)
    }
}
