import Foundation
@testable import cleanBrowser

final class BrowserSessionPersistenceSpy: BrowserSessionPersisting {
    var loadedState: BrowserSessionState
    private(set) var savedStates: [BrowserSessionState] = []
    var onSave: ((BrowserSessionState) -> Void)?

    init(loadedState: BrowserSessionState) {
        self.loadedState = loadedState
    }

    func load() -> BrowserSessionState {
        loadedState
    }

    func save(_ state: BrowserSessionState) {
        savedStates.append(state)
        onSave?(state)
    }
}

final class PINServiceStub: PINManaging {
    var isFirstLaunch: Bool
    var hasPINSet: Bool
    var expectedPIN: String
    private(set) var updatedPINs: [String] = []

    init(
        isFirstLaunch: Bool = false,
        hasPINSet: Bool = true,
        expectedPIN: String = "1234"
    ) {
        self.isFirstLaunch = isFirstLaunch
        self.hasPINSet = hasPINSet
        self.expectedPIN = expectedPIN
    }

    func verifyPIN(_ pin: String) -> Bool {
        pin == expectedPIN
    }

    func updatePIN(_ newPIN: String) {
        updatedPINs.append(newPIN)
        expectedPIN = newPIN
        hasPINSet = true
        isFirstLaunch = false
    }
}
