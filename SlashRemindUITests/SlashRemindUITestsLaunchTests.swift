//
//  SlashRemindUITestsLaunchTests.swift
//  SlashRemindUITests
//
//  Created by Maurice Le Cordier on 2025/09/02.
//

import XCTest

final class SlashRemindUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 3) || app.wait(for: .runningBackground, timeout: 3))
    }
}
