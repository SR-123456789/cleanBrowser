import Foundation
import AVFoundation
import UIKit

final class SoundDetector {
    static let shared = SoundDetector()

    private var engine: AVAudioEngine?
    private var lastAlertAt: Date?
    private let debounceSeconds: TimeInterval = 10
    private let threshold: Float = 0.05

    private init() {}

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
        input.installTap(onBus: bus, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            let rms = self.rms(buffer: buffer)
            if rms > self.threshold {
                DispatchQueue.main.async {
                    let now = Date()
                    if let last = self.lastAlertAt, now.timeIntervalSince(last) < self.debounceSeconds { return }
                    self.lastAlertAt = now
                    self.showAlert(rms: rms)
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

    private func rms(buffer: AVAudioPCMBuffer) -> Float {
        guard let data = buffer.floatChannelData else { return 0 }
        let ptr = data.pointee
        let len = Int(buffer.frameLength)
        var sum: Float = 0
        for i in 0..<len { let v = ptr[i]; sum += v * v }
        let mean = sum / Float(len)
        return sqrtf(mean)
    }

    private func showAlert(rms: Float) {
        let title = "足音を検知しました"
        let msg = String(format: "検出レベル: %.2f", rms)
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            root.present(alert, animated: true)
        } else if let window = UIApplication.shared.delegate?.window ?? nil {
            (window as? UIWindow)?.rootViewController?.present(alert, animated: true)
        }
    }
}
