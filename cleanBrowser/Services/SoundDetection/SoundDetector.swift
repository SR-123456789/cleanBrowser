import Foundation
import AVFoundation
import Combine
import UIKit

final class SoundDetector: ObservableObject {
    @Published private(set) var isEnabled: Bool
    @Published private(set) var dbThreshold: Float
    @Published private(set) var liveDb: Float?

    private var engine: AVAudioEngine?
    private var lastAlertAt: Date?
    private let debounceSeconds: TimeInterval = 10
    private let defaultDbThreshold: Float = -30.0
    private var lastDbPostAt: Date?
    private let dbPostInterval: TimeInterval = 0.5
    private var cachedDbThreshold: Float
    private let userDefaults: UserDefaults
    private let enabledKey = "SoundDetectionEnabled"
    private let thresholdKey = "SoundDetectionDbThreshold"
    private var temporarySuspensionCount = 0
    private var shouldResumeAfterTemporarySuspension = false

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        let persistedThreshold = userDefaults.object(forKey: thresholdKey) != nil
            ? userDefaults.float(forKey: thresholdKey)
            : defaultDbThreshold
        self.cachedDbThreshold = persistedThreshold
        self.dbThreshold = persistedThreshold
        self.isEnabled = userDefaults.object(forKey: enabledKey) != nil
            ? userDefaults.bool(forKey: enabledKey)
            : false
        self.liveDb = nil

        if isEnabled {
            startIfNeeded()
        }
    }

    var isRunning: Bool { engine != nil }

    func startIfNeeded() {
        guard isEnabled else { return }
        if engine != nil { return }
        start()
    }

    func stop() {
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        engine = nil
        DispatchQueue.main.async {
            self.liveDb = nil
        }
    }

    func setEnabled(_ enabled: Bool) {
        guard isEnabled != enabled else { return }
        isEnabled = enabled
        userDefaults.set(enabled, forKey: enabledKey)

        if enabled {
            startIfNeeded()
        } else {
            stop()
        }
    }

    func setDbThreshold(_ value: Float) {
        cachedDbThreshold = value
        dbThreshold = value
        userDefaults.set(value, forKey: thresholdKey)
    }

    func suspendTemporarily() {
        temporarySuspensionCount += 1
        guard temporarySuspensionCount == 1 else { return }

        shouldResumeAfterTemporarySuspension = isEnabled
        stop()
    }

    func resumeTemporarily() {
        guard temporarySuspensionCount > 0 else { return }
        temporarySuspensionCount -= 1
        guard temporarySuspensionCount == 0 else { return }

        let shouldResume = shouldResumeAfterTemporarySuspension && isEnabled
        shouldResumeAfterTemporarySuspension = false

        if shouldResume {
            startIfNeeded()
        }
    }

    private func start() {
        let eng = AVAudioEngine()
        let input = eng.inputNode
        let bus = 0
        let format = input.inputFormat(forBus: bus)
        let bufferSize: AVAudioFrameCount = 4096
        input.installTap(onBus: bus, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            let rms = self.rms(buffer: buffer, maxSamples: 1024)
            let db = 20.0 * log10(max(rms, 1e-10))
            let now = Date()
            if self.lastDbPostAt == nil || now.timeIntervalSince(self.lastDbPostAt!) >= self.dbPostInterval {
                self.lastDbPostAt = now
                DispatchQueue.main.async {
                    self.liveDb = db
                }
            }
            if db > self.cachedDbThreshold {
                DispatchQueue.main.async {
                    let now = Date()
                    if let last = self.lastAlertAt, now.timeIntervalSince(last) < self.debounceSeconds { return }
                    self.lastAlertAt = now
                    self.showAlert(rms: rms, db: db)
                }
            }
        }
        do {
            try eng.start()
            engine = eng
        } catch {
            print("SoundDetector: failed to start engine: \(error)")
        }
    }

    private func rms(buffer: AVAudioPCMBuffer, maxSamples: Int = Int.max) -> Float {
        guard let data = buffer.floatChannelData else { return 0 }
        let ptr = data.pointee
        let len = Int(buffer.frameLength)
        if len == 0 { return 0 }
        let step = max(1, len / max(1, min(len, maxSamples)))
        var sum: Float = 0
        var count = 0
        var i = 0
        while i < len {
            let v = ptr[i]
            sum += v * v
            count += 1
            i += step
        }
        let mean = sum / Float(max(1, count))
        return sqrtf(mean)
    }

    private func showAlert(rms: Float, db: Float) {
        let title = "注意：足音を検知しました"
        let msg = String(format: "検出レベル: %.2f (%.1f dB)", rms, db)
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        alert.addAction(UIAlertAction(title: "検知を停止", style: .destructive, handler: { _ in
            self.setEnabled(false)
        }))
        alert.addAction(UIAlertAction(title: "感度を変更", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            let sheet = UIAlertController(title: "感度プリセット", message: "プリセットを選択してください", preferredStyle: .actionSheet)
            let presets: [(String, Float)] = [("高感度", -50.0), ("中（既定）", -30.0), ("低感度", -20.0)]
            for p in presets {
                sheet.addAction(UIAlertAction(title: p.0, style: .default, handler: { _ in
                    self.setDbThreshold(p.1)
                }))
            }
            sheet.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
            ViewControllerLocator.topViewController()?.present(sheet, animated: true)
        }))
        ViewControllerLocator.topViewController()?.present(alert, animated: true)
    }
}
