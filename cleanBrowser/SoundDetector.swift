import Foundation
import AVFoundation
import UIKit

final class SoundDetector {
    static let shared = SoundDetector()

    private var engine: AVAudioEngine?
    private var lastAlertAt: Date?
    private let debounceSeconds: TimeInterval = 10
    // RSS linear threshold removed; we will use dBFS threshold from UserDefaults
    private let defaultDbThreshold: Float = -30.0
    private var lastDbPostAt: Date?
    private let dbPostInterval: TimeInterval = 0.5
    // Cache the threshold to avoid reading UserDefaults every audio callback
    private var cachedDbThreshold: Float

    private init() {
        self.cachedDbThreshold = UserDefaults.standard.object(forKey: "SoundDetectionDbThreshold") as? Float ?? defaultDbThreshold
    }

    func setDbThreshold(_ v: Float) {
        cachedDbThreshold = v
    }

    var isRunning: Bool { engine != nil }

    func startIfNeeded() {
    // Default to false when the flag is not present
    let enabled = UserDefaults.standard.object(forKey: "SoundDetectionEnabled") as? Bool ?? false
    guard enabled else { return }
        if engine != nil { return }
        start()
    }

    func stop() {
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        engine = nil
    }

    private func start() {
        let eng = AVAudioEngine()
        let input = eng.inputNode
        let bus = 0
        let format = input.inputFormat(forBus: bus)
        // use a larger buffer to reduce callback frequency and CPU churn
        let bufferSize: AVAudioFrameCount = 4096
        input.installTap(onBus: bus, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
        // Compute RMS with light-weight downsampling to reduce CPU
        let rms = self.rms(buffer: buffer, maxSamples: 1024)
        // convert to dBFS
            let db = 20.0 * log10(max(rms, 1e-10))
            // Post live dB updates at most every dbPostInterval seconds
            let now = Date()
            if self.lastDbPostAt == nil || now.timeIntervalSince(self.lastDbPostAt!) >= self.dbPostInterval {
                self.lastDbPostAt = now
                // post on current thread (audio thread) - subscriber receives on main
                NotificationCenter.default.post(name: Notification.Name("SoundDetectorDidUpdateDb"), object: nil, userInfo: ["db": NSNumber(value: db)])
            }
            // use cached threshold for faster comparison
            let dbThreshold = self.cachedDbThreshold
            if db > dbThreshold {
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
        // If the buffer is large, downsample by skipping samples to limit CPU.
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
        // 検知をオフにするアクション
        alert.addAction(UIAlertAction(title: "検知を停止", style: .destructive, handler: { _ in
            UserDefaults.standard.set(false, forKey: "SoundDetectionEnabled")
            SoundDetector.shared.stop()
            NotificationCenter.default.post(name: Notification.Name("SoundDetectionEnabledChanged"), object: nil, userInfo: ["enabled": NSNumber(value: false)])
        }))
        // 感度変更アクション（プリセット）
        alert.addAction(UIAlertAction(title: "感度を変更", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            // Present an action sheet with presets
            let sheet = UIAlertController(title: "感度プリセット", message: "プリセットを選択してください", preferredStyle: .actionSheet)
            let presets: [(String, Float)] = [("高感度", -50.0), ("中（既定）", -30.0), ("低感度", -20.0)]
            for p in presets {
                sheet.addAction(UIAlertAction(title: p.0, style: .default, handler: { _ in
                    UserDefaults.standard.set(p.1, forKey: "SoundDetectionDbThreshold")
                    SoundDetector.shared.setDbThreshold(p.1)
                    NotificationCenter.default.post(name: Notification.Name("SoundDetectorDidChangeDbThreshold"), object: nil, userInfo: ["db": NSNumber(value: p.1)])
                }))
            }
            sheet.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                root.present(sheet, animated: true)
            }
        }))
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            root.present(alert, animated: true)
        } else if let window = UIApplication.shared.delegate?.window ?? nil {
            (window as? UIWindow)?.rootViewController?.present(alert, animated: true)
        }
    }
}
