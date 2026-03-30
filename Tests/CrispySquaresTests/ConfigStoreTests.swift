import XCTest
@testable import CrispySquares

final class ConfigStoreTests: XCTestCase {

    var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("CrispySquaresTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testSaveAndLoadConfig() throws {
        let store = ConfigStore(directory: tempDir)
        var config = AppConfig()
        config.globalFontSmoothing = 2
        config.displaySettings["ABC123"] = DisplaySettings(
            gammaCurve: .parametric(gamma: 1.8),
            profileName: "Bold Text"
        )
        try store.save(config)
        let loaded = try store.load()
        XCTAssertEqual(loaded.globalFontSmoothing, 2)
        XCTAssertEqual(loaded.displaySettings["ABC123"]?.profileName, "Bold Text")
    }

    func testLoadReturnsDefaultWhenNoFile() throws {
        let store = ConfigStore(directory: tempDir)
        let config = try store.load()
        XCTAssertEqual(config.globalFontSmoothing, nil)
        XCTAssertTrue(config.displaySettings.isEmpty)
        XCTAssertTrue(config.appOverrides.isEmpty)
        XCTAssertTrue(config.customPresets.isEmpty)
    }

    func testAppOverridesPersist() throws {
        let store = ConfigStore(directory: tempDir)
        var config = AppConfig()
        config.appOverrides["com.apple.Terminal"] = 0
        config.appOverrides["com.googlecode.iterm2"] = 3
        try store.save(config)
        let loaded = try store.load()
        XCTAssertEqual(loaded.appOverrides["com.apple.Terminal"], 0)
        XCTAssertEqual(loaded.appOverrides["com.googlecode.iterm2"], 3)
    }

    func testCustomPresetsPersist() throws {
        let store = ConfigStore(directory: tempDir)
        var config = AppConfig()
        config.customPresets.append(
            Preset(name: "My Curve", curve: .parametric(gamma: 1.7), isBuiltIn: false)
        )
        try store.save(config)
        let loaded = try store.load()
        XCTAssertEqual(loaded.customPresets.count, 1)
        XCTAssertEqual(loaded.customPresets[0].name, "My Curve")
    }
}
