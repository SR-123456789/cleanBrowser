import SwiftUI
import UIKit

struct WindowTapSpyView: UIViewRepresentable {
    let isEnabled: Bool
    let onTap: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onTap = onTap
        if isEnabled {
            context.coordinator.attachIfNeeded(from: uiView)
        } else {
            context.coordinator.detach()
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.detach()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onTap: () -> Void
        private weak var attachedView: UIView?
        private lazy var tapRecognizer: UITapGestureRecognizer = {
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            recognizer.cancelsTouchesInView = false
            recognizer.delaysTouchesBegan = false
            recognizer.delaysTouchesEnded = false
            recognizer.delegate = self
            return recognizer
        }()

        init(onTap: @escaping () -> Void) {
            self.onTap = onTap
        }

        func attachIfNeeded(from view: UIView) {
            guard let hostView = gestureHostView(from: view) else { return }
            guard attachedView !== hostView else { return }

            detach()
            hostView.addGestureRecognizer(tapRecognizer)
            attachedView = hostView
        }

        func detach() {
            attachedView?.removeGestureRecognizer(tapRecognizer)
            attachedView = nil
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard
                let attachedView,
                let touchedView = touch.view
            else {
                return false
            }

            return touchedView.isDescendant(of: attachedView)
        }

        @objc
        private func handleTap() {
            onTap()
        }

        private func gestureHostView(from view: UIView) -> UIView? {
            var currentView = view.superview

            while let candidate = currentView, !(candidate is UIWindow) {
                if candidate.bounds.width > 1, candidate.bounds.height > 1 {
                    return candidate
                }
                currentView = candidate.superview
            }

            return view.superview
        }
    }
}
