import XCTest
@testable import cleanBrowser

@MainActor
final class BrowserStoreTests: XCTestCase {
    func test_init_createsDefaultTabWhenNoTabsPersisted() {
        let (store, _) = makeStore(state: .init(
            tabs: [],
            activeTabIndex: 0,
            confirmNavigation: true,
            isMutedGlobal: false,
            customKeyboardEnabled: false,
            systemKeyboardUseCount: 0,
            hasAcknowledgedCustomKeyboardGuide: false
        ))

        XCTAssertEqual(store.tabs.count, 1)
        XCTAssertEqual(store.activeTabIndex, 0)
        XCTAssertEqual(store.activeTab?.url, BrowserURLResolver.defaultHomePage)
    }

    func test_init_clampsRestoredActiveTabIndex() {
        let (store, _) = makeStore(state: .init(
            tabs: [
                .init(url: "https://first.example", title: "First"),
                .init(url: "https://second.example", title: "Second"),
            ],
            activeTabIndex: 99,
            confirmNavigation: true,
            isMutedGlobal: false,
            customKeyboardEnabled: false,
            systemKeyboardUseCount: 0,
            hasAcknowledgedCustomKeyboardGuide: false
        ))

        XCTAssertEqual(store.activeTabIndex, 1)
        XCTAssertEqual(store.activeTab?.url, "https://second.example")
    }

    func test_addNewTab_activatesNewTabAndPersists() {
        let (store, persistence) = makeStore()

        store.addNewTab(url: "https://example.com")

        XCTAssertEqual(store.tabs.count, 2)
        XCTAssertEqual(store.activeTabIndex, 1)
        XCTAssertEqual(store.activeTab?.url, "https://example.com")
        XCTAssertEqual(persistence.savedStates.last?.tabs.count, 2)
        XCTAssertEqual(persistence.savedStates.last?.activeTabIndex, 1)
    }

    func test_closeTab_keepsAtLeastOneTab() {
        let (store, persistence) = makeStore()

        store.closeTab(at: 0)

        XCTAssertEqual(store.tabs.count, 1)
        XCTAssertTrue(persistence.savedStates.isEmpty)
    }

    func test_tabURLAndTitleChangesPersistCurrentSession() async {
        let (store, persistence) = makeStore()
        let expectation = expectation(description: "Persist updated title")
        persistence.onSave = { state in
            if state.tabs.first?.title == "Updated" {
                expectation.fulfill()
            }
        }

        store.tabs[0].url = "https://example.com/page"
        store.tabs[0].title = "Updated"
        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertEqual(persistence.savedStates.last?.tabs.first?.url, "https://example.com/page")
        XCTAssertEqual(persistence.savedStates.last?.tabs.first?.title, "Updated")
    }

    func test_tabURLAndTitleChanges_areDebouncedIntoSinglePersist() {
        let persistence = BrowserSessionPersistenceSpy(loadedState: .init(
            tabs: [.init(url: BrowserURLResolver.defaultHomePage, title: "新しいタブ")],
            activeTabIndex: 0,
            confirmNavigation: true,
            isMutedGlobal: false,
            customKeyboardEnabled: false,
            systemKeyboardUseCount: 0,
            hasAcknowledgedCustomKeyboardGuide: false
        ))
        var scheduledWorkItems: [DispatchWorkItem] = []
        let store = BrowserStore(
            persistence: persistence,
            persistDebounceInterval: 1,
            scheduleDelayedWork: { _, workItem in
                scheduledWorkItems.append(workItem)
            }
        )

        store.tabs[0].url = "https://example.com/page"
        store.tabs[0].title = "Updated"

        XCTAssertEqual(persistence.savedStates.count, 0)
        XCTAssertEqual(scheduledWorkItems.count, 2)
        XCTAssertTrue(scheduledWorkItems[0].isCancelled)

        scheduledWorkItems[1].perform()

        XCTAssertEqual(persistence.savedStates.count, 1)
        XCTAssertEqual(persistence.savedStates.last?.tabs.first?.url, "https://example.com/page")
        XCTAssertEqual(persistence.savedStates.last?.tabs.first?.title, "Updated")
    }

    func test_toggleGlobalMute_updatesAllTabs() {
        let (store, _) = makeStore()
        store.addNewTab(url: "https://second.example")

        store.toggleGlobalMute()

        XCTAssertTrue(store.isMutedGlobal)
        XCTAssertTrue(store.tabs.allSatisfy(\.isMuted))
    }

    func test_recordSystemKeyboardUse_incrementsCounterAndPersists() {
        let (store, persistence) = makeStore()

        store.recordSystemKeyboardUse()

        XCTAssertEqual(store.systemKeyboardUseCount, 1)
        XCTAssertTrue(store.shouldSuggestCustomKeyboardGuide)
        XCTAssertEqual(persistence.savedStates.last?.systemKeyboardUseCount, 1)
        XCTAssertEqual(persistence.savedStates.last?.hasAcknowledgedCustomKeyboardGuide, false)
    }

    func test_acknowledgeCustomKeyboardGuide_stopsFurtherPrompting() {
        let (store, persistence) = makeStore(state: .init(
            tabs: [.init(url: BrowserURLResolver.defaultHomePage, title: "新しいタブ")],
            activeTabIndex: 0,
            confirmNavigation: true,
            isMutedGlobal: false,
            customKeyboardEnabled: false,
            systemKeyboardUseCount: 1,
            hasAcknowledgedCustomKeyboardGuide: false
        ))

        store.acknowledgeCustomKeyboardGuide()
        store.recordSystemKeyboardUse()

        XCTAssertTrue(store.hasAcknowledgedCustomKeyboardGuide)
        XCTAssertFalse(store.shouldSuggestCustomKeyboardGuide)
        XCTAssertEqual(store.systemKeyboardUseCount, 1)
        XCTAssertEqual(persistence.savedStates.last?.hasAcknowledgedCustomKeyboardGuide, true)
    }

    func test_enablingCustomKeyboard_marksGuideAsAcknowledged() {
        let (store, persistence) = makeStore(state: .init(
            tabs: [.init(url: BrowserURLResolver.defaultHomePage, title: "新しいタブ")],
            activeTabIndex: 0,
            confirmNavigation: true,
            isMutedGlobal: false,
            customKeyboardEnabled: false,
            systemKeyboardUseCount: 1,
            hasAcknowledgedCustomKeyboardGuide: false
        ))

        store.enableCustomKeyboard()

        XCTAssertTrue(store.customKeyboardEnabled)
        XCTAssertTrue(store.hasAcknowledgedCustomKeyboardGuide)
        XCTAssertEqual(persistence.savedStates.last?.customKeyboardEnabled, true)
        XCTAssertEqual(persistence.savedStates.last?.hasAcknowledgedCustomKeyboardGuide, true)
    }

    func test_shouldConfirmNavigation_skipsSameHostAndSearchEngineSources() {
        let (store, _) = makeStore()

        XCTAssertFalse(
            store.shouldConfirmNavigation(
                current: URL(string: "https://example.com/page"),
                target: URL(string: "https://example.com/other")!,
                sourceHost: "example.com"
            )
        )
        XCTAssertFalse(
            store.shouldConfirmNavigation(
                current: URL(string: "https://www.google.com/search?q=test"),
                target: URL(string: "https://target.example")!,
                sourceHost: "www.google.com"
            )
        )
        XCTAssertTrue(
            store.shouldConfirmNavigation(
                current: URL(string: "https://source.example"),
                target: URL(string: "https://target.example")!,
                sourceHost: "source.example"
            )
        )
    }

    func test_cancelledExternalNavigationRecovery_closesFreshRedirectTabAndReturnsToOpener() {
        let openerID = UUID()
        let action = CancelledExternalNavigationRecoveryPolicy.action(
            for: .init(
                openerTabID: openerID,
                creationSource: .pageOpened
            )
        )

        XCTAssertEqual(action, .closeCurrentTabAndReturnToOpener(openerID))
    }

    func test_cancelledExternalNavigationRecovery_doesNotCloseForManualTab() {
        let action = CancelledExternalNavigationRecoveryPolicy.action(
            for: .init(
                openerTabID: UUID(),
                creationSource: .manual
            )
        )

        XCTAssertEqual(action, .none)
    }

    func test_cancelledExternalNavigationRecovery_doesNotCloseForUserOpenedTab() {
        let action = CancelledExternalNavigationRecoveryPolicy.action(
            for: .init(
                openerTabID: UUID(),
                creationSource: .userOpened
            )
        )

        XCTAssertEqual(action, .none)
    }

    private func makeStore(
        state: BrowserSessionState = .init(
            tabs: [.init(url: BrowserURLResolver.defaultHomePage, title: "新しいタブ")],
            activeTabIndex: 0,
            confirmNavigation: true,
            isMutedGlobal: false,
            customKeyboardEnabled: false,
            systemKeyboardUseCount: 0,
            hasAcknowledgedCustomKeyboardGuide: false
        )
    ) -> (BrowserStore, BrowserSessionPersistenceSpy) {
        let persistence = BrowserSessionPersistenceSpy(loadedState: state)
        return (
            BrowserStore(
                persistence: persistence,
                persistDebounceInterval: 0,
                scheduleDelayedWork: { _, workItem in
                    workItem.perform()
                }
            ),
            persistence
        )
    }
}
