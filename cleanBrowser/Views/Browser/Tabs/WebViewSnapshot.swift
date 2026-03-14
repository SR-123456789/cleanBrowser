import SwiftUI
import WebKit

struct WebViewSnapshot: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.systemBackground

        webView.takeSnapshot(with: nil) { image, _ in
            DispatchQueue.main.async {
                guard let image else { return }

                let imageView = UIImageView(image: image)
                imageView.contentMode = .scaleAspectFit
                imageView.frame = containerView.bounds
                imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                containerView.addSubview(imageView)
            }
        }

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
