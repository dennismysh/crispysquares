import XCTest
@testable import CrispySquares

final class FontSmoothingServiceTests: XCTestCase {
    var service: FontSmoothingService!

    override func setUp() {
        super.setUp()
        service = FontSmoothingService()
    }

    func testReadGlobalFontSmoothing() {
        let value = service.globalFontSmoothing
        XCTAssertTrue(value == nil || (0...3).contains(value!))
    }

    func testSetAndReadGlobalFontSmoothing() {
        let originalValue = service.globalFontSmoothing
        service.globalFontSmoothing = 2
        XCTAssertEqual(service.globalFontSmoothing, 2)
        if let orig = originalValue {
            service.globalFontSmoothing = orig
        } else {
            service.removeGlobalFontSmoothing()
        }
    }

    func testListInstalledApps() {
        let apps = service.installedApps()
        XCTAssertFalse(apps.isEmpty)
        for app in apps {
            XCTAssertFalse(app.bundleIdentifier.isEmpty)
            XCTAssertFalse(app.name.isEmpty)
        }
    }
}
