import XCTest
@testable import SlashRemind

final class DoublePressDetectorTests: XCTestCase {
    func testDetectsDoublePressWithinThreshold() {
        let detector = DoublePressDetector(threshold: 0.3)
        XCTAssertFalse(detector.register(keyCode: 0x2C))
        XCTAssertTrue(detector.register(keyCode: 0x2C))
    }

    func testIgnoresSlowPresses() {
        let detector = DoublePressDetector(threshold: 0.05)
        XCTAssertFalse(detector.register(keyCode: 0x2C))
        usleep(100_000)
        XCTAssertFalse(detector.register(keyCode: 0x2C))
    }

    func testIgnoresRepeats() {
        let detector = DoublePressDetector()
        XCTAssertFalse(detector.register(keyCode: 0x2C, isRepeat: true))
    }
}
