import XCTest
@testable import cleanBrowser

@MainActor
final class CustomKeyboardViewModelTests: XCTestCase {
    func test_flickOptions_followJapaneseDirectionalLayout() {
        let sut = CustomKeyboardViewModel()
        sut.currentLayout = .hiragana

        let options = sut.flickOptions(for: "あ")

        XCTAssertEqual(options[.left], "い")
        XCTAssertEqual(options[.up], "う")
        XCTAssertEqual(options[.right], "え")
        XCTAssertEqual(options[.down], "お")
    }

    func test_flickOptions_forShortCycleOnlyReturnsAvailableDirections() {
        let sut = CustomKeyboardViewModel()
        sut.currentLayout = .hiragana

        let options = sut.flickOptions(for: "や")

        XCTAssertEqual(options[.up], "ゆ")
        XCTAssertEqual(options[.right], "よ")
        XCTAssertNil(options[.down])
        XCTAssertNil(options[.left])
    }

    func test_handleJapaneseInput_withFlickInsertsMappedCharacterAndResetsTapCycleState() {
        var insertedTexts: [String] = []
        let sut = CustomKeyboardViewModel(
            insertTextHandler: { insertedTexts.append($0) },
            deleteTextHandler: {}
        )
        sut.currentLayout = .hiragana
        sut.lastPressedKey = "あ"
        sut.lastPressedKeyIndex = 3
        sut.lastKeyPressTime = Date()

        sut.handleJapaneseInput("か", flickDirection: .right)

        XCTAssertEqual(insertedTexts, ["く"])
        XCTAssertNil(sut.lastPressedKey)
        XCTAssertEqual(sut.lastPressedKeyIndex, 0)
        XCTAssertEqual(sut.lastOutputChar, "く")
    }

    func test_handleJapaneseInput_withoutFlickKeepsExistingTapCycleBehavior() {
        var insertedTexts: [String] = []
        var deleteCallCount = 0
        let sut = CustomKeyboardViewModel(
            insertTextHandler: { insertedTexts.append($0) },
            deleteTextHandler: { deleteCallCount += 1 }
        )
        sut.currentLayout = .hiragana

        sut.handleJapaneseInput("あ", flickDirection: nil)
        sut.handleJapaneseInput("あ", flickDirection: nil)

        XCTAssertEqual(insertedTexts, ["あ", "い"])
        XCTAssertEqual(deleteCallCount, 1)
        XCTAssertEqual(sut.lastOutputChar, "い")
    }
}
