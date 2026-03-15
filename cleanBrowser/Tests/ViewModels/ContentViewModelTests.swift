import XCTest
import SwiftUI
@testable import cleanBrowser

@MainActor
final class ContentViewModelTests: XCTestCase {
    func test_shouldShowInitialSetup_whenFirstLaunchAndPINIsNotSet() {
        let sut = ContentViewModel(
            pinService: PINServiceStub(isFirstLaunch: true, hasPINSet: false)
        )

        XCTAssertTrue(sut.shouldShowInitialSetup)
    }

    func test_verifyPIN_unlocksOnSuccess() {
        let sut = ContentViewModel(
            pinService: PINServiceStub(expectedPIN: "1234")
        )

        sut.verifyPIN("1234")

        XCTAssertTrue(sut.isUnlocked)
        XCTAssertNil(sut.errorMessage)
    }

    func test_backgroundThenActive_relocksWhenPINIsSet() {
        let sut = ContentViewModel(
            pinService: PINServiceStub(isFirstLaunch: false, hasPINSet: true)
        )
        sut.isUnlocked = true

        sut.handleScenePhase(.background)

        XCTAssertTrue(sut.isPrivacyShieldVisible)

        sut.handleScenePhase(.active)

        XCTAssertFalse(sut.isUnlocked)
        XCTAssertFalse(sut.isPrivacyShieldVisible)
    }

    func test_inactiveSchedulesPrivacyShield() {
        var scheduledWorkItems: [DispatchWorkItem] = []
        let sut = ContentViewModel(
            pinService: PINServiceStub(),
            inactiveShieldDelay: 1,
            scheduleDelayedWork: { _, workItem in
                scheduledWorkItems.append(workItem)
            }
        )

        sut.handleScenePhase(.inactive)

        XCTAssertFalse(sut.isPrivacyShieldVisible)
        XCTAssertEqual(scheduledWorkItems.count, 1)

        scheduledWorkItems[0].perform()

        XCTAssertTrue(sut.isPrivacyShieldVisible)
    }

    func test_activeCancelsPendingInactiveShield() {
        var scheduledWorkItems: [DispatchWorkItem] = []
        let sut = ContentViewModel(
            pinService: PINServiceStub(),
            inactiveShieldDelay: 1,
            scheduleDelayedWork: { _, workItem in
                scheduledWorkItems.append(workItem)
            }
        )

        sut.handleScenePhase(.inactive)
        sut.handleScenePhase(.active)

        XCTAssertEqual(scheduledWorkItems.count, 1)
        XCTAssertTrue(scheduledWorkItems[0].isCancelled)
        XCTAssertFalse(sut.isPrivacyShieldVisible)
    }
}
