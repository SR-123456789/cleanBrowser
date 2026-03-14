import UIKit

protocol NavigationConfirmationPresenting {
    func confirmNavigation(
        to target: String,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    )
}

struct SystemNavigationConfirmationPresenter: NavigationConfirmationPresenting {
    func confirmNavigation(
        to target: String,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        let alert = UIAlertController(title: "移動しますか？", message: target, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel) { _ in
            onCancel()
        })
        alert.addAction(UIAlertAction(title: "移動", style: .default) { _ in
            onConfirm()
        })

        guard let viewController = ViewControllerLocator.topViewController() else {
            onConfirm()
            return
        }

        viewController.present(alert, animated: true)
    }
}
