import Combine
import SwiftUI

@MainActor
final class TabOverviewViewModel: ObservableObject {
    let browserStore: BrowserStore

    private var cancellables = Set<AnyCancellable>()

    init(browserStore: BrowserStore) {
        self.browserStore = browserStore

        browserStore.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    var tabs: [BrowserTab] {
        browserStore.tabs
    }

    var activeTabIndex: Int {
        browserStore.activeTabIndex
    }

    var navigationTitle: String {
        "\(browserStore.tabs.count)個のタブ"
    }

    func addTabAndSelect() {
        browserStore.addNewTab()
        browserStore.switchToTab(at: browserStore.tabs.count - 1)
    }

    func selectTab(at index: Int) {
        browserStore.switchToTab(at: index)
    }

    func closeTab(at index: Int) {
        browserStore.closeTab(at: index)
    }
}
