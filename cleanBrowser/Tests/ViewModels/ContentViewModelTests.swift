import XCTest
import SwiftUI
@testable import cleanBrowser

@MainActor
final class ContentViewModelTests: XCTestCase {
    func test_shouldShowInitialSetup_whenFirstLaunchAndPINIsNotSet() {
        let sut = ContentViewModel(
            pinService: PINServiceStub(isFirstLaunch: true, hasPINSet: false),
            startupAdVisibilityController: StartupAdVisibilityControllerSpy()
        )

        XCTAssertTrue(sut.shouldShowInitialSetup)
    }

    func test_verifyPIN_unlocksOnSuccess() {
        let sut = ContentViewModel(
            pinService: PINServiceStub(expectedPIN: "1234"),
            startupAdVisibilityController: StartupAdVisibilityControllerSpy()
        )

        sut.verifyPIN("1234")

        XCTAssertTrue(sut.isUnlocked)
        XCTAssertNil(sut.errorMessage)
    }

    func test_backgroundThenActive_relocksWhenPINIsSet() {
        let sut = ContentViewModel(
            pinService: PINServiceStub(isFirstLaunch: false, hasPINSet: true),
            startupAdVisibilityController: StartupAdVisibilityControllerSpy()
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
            startupAdVisibilityController: StartupAdVisibilityControllerSpy(),
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
            startupAdVisibilityController: StartupAdVisibilityControllerSpy(),
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

    func test_loadStartupIfNeeded_showsMandatoryPromptAndDisablesDailyInterstitial() async {
        let startupLoader = StartupLoaderStub()
        startupLoader.response = StartupResponse(
            update: StartupUpdateResponse(
                mustUpdate: true,
                shouldUpdate: false,
                repeatUpdatePrompt: false,
                updateLink: "https://apps.apple.com/app/id1234567890",
                message: "このバージョンはサポート対象外です。"
            ),
            ads: [
                StartupAdVisibilityResponse(adID: "daily_interstitial", isShow: false)
            ]
        )
        let adVisibilityController = StartupAdVisibilityControllerSpy()
        let sut = ContentViewModel(
            pinService: PINServiceStub(),
            startupLoader: startupLoader,
            startupAdVisibilityController: adVisibilityController,
            updatePromptHistoryStore: StartupUpdatePromptHistoryStoreStub(),
            appVersionProvider: { "2.1.4" }
        )

        sut.loadStartupIfNeeded()
        await Task.yield()

        XCTAssertEqual(startupLoader.requestedAppVersions, ["2.1.4"])
        XCTAssertEqual(adVisibilityController.isDailyInterstitialVisible, false)
        XCTAssertEqual(sut.startupUpdatePrompt?.isMandatory, true)
        XCTAssertEqual(sut.startupUpdatePrompt?.message, "このバージョンはサポート対象外です。")
    }

    func test_loadStartupIfNeeded_showsOptionalPromptOnlyOncePerVersionAndMessage() async {
        let startupLoader = StartupLoaderStub()
        startupLoader.response = StartupResponse(
            update: StartupUpdateResponse(
                mustUpdate: false,
                shouldUpdate: true,
                repeatUpdatePrompt: false,
                updateLink: "https://apps.apple.com/app/id1234567890",
                message: "アップデートしてください。"
            ),
            ads: []
        )
        let historyStore = StartupUpdatePromptHistoryStoreStub()
        let sut = ContentViewModel(
            pinService: PINServiceStub(),
            startupLoader: startupLoader,
            startupAdVisibilityController: StartupAdVisibilityControllerSpy(),
            updatePromptHistoryStore: historyStore,
            appVersionProvider: { "2.1.4" }
        )

        sut.loadStartupIfNeeded()
        await Task.yield()

        XCTAssertEqual(sut.startupUpdatePrompt?.isMandatory, false)
        XCTAssertEqual(historyStore.markedEntries.count, 1)

        let secondLoader = StartupLoaderStub()
        secondLoader.response = startupLoader.response
        let secondSut = ContentViewModel(
            pinService: PINServiceStub(),
            startupLoader: secondLoader,
            startupAdVisibilityController: StartupAdVisibilityControllerSpy(),
            updatePromptHistoryStore: historyStore,
            appVersionProvider: { "2.1.4" }
        )

        secondSut.loadStartupIfNeeded()
        await Task.yield()

        XCTAssertNil(secondSut.startupUpdatePrompt)
        XCTAssertEqual(historyStore.markedEntries.count, 1)
    }

    func test_loadStartupIfNeeded_repeatPromptAlwaysShows() async {
        let startupLoader = StartupLoaderStub()
        startupLoader.response = StartupResponse(
            update: StartupUpdateResponse(
                mustUpdate: false,
                shouldUpdate: true,
                repeatUpdatePrompt: true,
                updateLink: "https://apps.apple.com/app/id1234567890",
                message: "毎回案内を出します。"
            ),
            ads: []
        )
        let historyStore = StartupUpdatePromptHistoryStoreStub()
        historyStore.shownKeys.insert("2.1.4\n毎回案内を出します。")
        let sut = ContentViewModel(
            pinService: PINServiceStub(),
            startupLoader: startupLoader,
            startupAdVisibilityController: StartupAdVisibilityControllerSpy(),
            updatePromptHistoryStore: historyStore,
            appVersionProvider: { "2.1.4" }
        )

        sut.loadStartupIfNeeded()
        await Task.yield()

        XCTAssertEqual(sut.startupUpdatePrompt?.isMandatory, false)
        XCTAssertEqual(sut.startupUpdatePrompt?.message, "毎回案内を出します。")
        XCTAssertTrue(historyStore.markedEntries.isEmpty)
    }

    func test_loadStartupIfNeeded_retriesAfterFailure() async {
        let startupLoader = StartupLoaderStub()
        startupLoader.error = TestError.expectedFailure
        let adVisibilityController = StartupAdVisibilityControllerSpy()
        adVisibilityController.isDailyInterstitialVisible = true
        let sut = ContentViewModel(
            pinService: PINServiceStub(),
            startupLoader: startupLoader,
            startupAdVisibilityController: adVisibilityController,
            updatePromptHistoryStore: StartupUpdatePromptHistoryStoreStub(),
            appVersionProvider: { "2.1.3" }
        )

        sut.loadStartupIfNeeded()
        await Task.yield()

        XCTAssertEqual(adVisibilityController.isDailyInterstitialVisible, false)

        startupLoader.error = nil
        startupLoader.response = StartupResponse(
            update: StartupUpdateResponse(
                mustUpdate: true,
                shouldUpdate: false,
                repeatUpdatePrompt: true,
                updateLink: "https://apps.apple.com/app/id1234567890",
                message: "このバージョンはサポート対象外です。"
            ),
            ads: []
        )

        sut.loadStartupIfNeeded()
        await Task.yield()

        XCTAssertEqual(startupLoader.requestedAppVersions, ["2.1.3", "2.1.3"])
        XCTAssertEqual(sut.startupUpdatePrompt?.isMandatory, true)
    }

    func test_loadStartupIfNeeded_hidesDailyInterstitialWhenStartupResponseOmitsAd() async {
        let startupLoader = StartupLoaderStub()
        startupLoader.response = StartupResponse(
            update: StartupUpdateResponse(
                mustUpdate: false,
                shouldUpdate: false,
                repeatUpdatePrompt: false,
                updateLink: "https://apps.apple.com/app/id1234567890",
                message: "現在のバージョンは最新です。"
            ),
            ads: []
        )
        let adVisibilityController = StartupAdVisibilityControllerSpy()
        adVisibilityController.isDailyInterstitialVisible = true
        let sut = ContentViewModel(
            pinService: PINServiceStub(),
            startupLoader: startupLoader,
            startupAdVisibilityController: adVisibilityController,
            updatePromptHistoryStore: StartupUpdatePromptHistoryStoreStub(),
            appVersionProvider: { "2.1.4" }
        )

        sut.loadStartupIfNeeded()
        await Task.yield()

        XCTAssertEqual(adVisibilityController.isDailyInterstitialVisible, false)
    }
}
