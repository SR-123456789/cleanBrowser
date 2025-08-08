import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var blackoutView: UIView?

    func sceneWillResignActive(_ scene: UIScene) {
        guard let window = window else { return }
        let blackoutView = UIView(frame: window.bounds)
        blackoutView.backgroundColor = .black
        blackoutView.tag = 999
        window.addSubview(blackoutView)
        self.blackoutView = blackoutView
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        blackoutView?.removeFromSuperview()
        blackoutView = nil
    }
}
