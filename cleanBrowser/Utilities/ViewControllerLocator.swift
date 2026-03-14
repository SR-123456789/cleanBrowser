import UIKit

enum ViewControllerLocator {
    static func topViewController() -> UIViewController? {
        let connectedScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let keyWindow = connectedScenes
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)

        return topViewController(from: keyWindow?.rootViewController)
    }

    private static func topViewController(from root: UIViewController?) -> UIViewController? {
        if let navigationController = root as? UINavigationController {
            return topViewController(from: navigationController.visibleViewController)
        }

        if let tabBarController = root as? UITabBarController {
            return topViewController(from: tabBarController.selectedViewController)
        }

        if let presented = root?.presentedViewController {
            return topViewController(from: presented)
        }

        return root
    }
}
