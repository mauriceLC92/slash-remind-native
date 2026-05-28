import XCTest

final class SlashRemindUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testQuickAddPaletteShowsAndDismissesWithEscape() throws {
        let app = XCUIApplication()
        app.launchEnvironment["SLASH_REMIND_SHOW_PALETTE_ON_LAUNCH"] = "1"
        app.launch()

        let textField = app.textFields["quickAddTextField"]
        XCTAssertTrue(textField.waitForExistence(timeout: 5))
        textField.typeText("buy milk tomorrow at 9am")
        XCTAssertEqual(textField.value as? String, "buy milk tomorrow at 9am")

        app.typeKey(.escape, modifierFlags: [])
        XCTAssertFalse(textField.waitForExistence(timeout: 1))
    }
}
