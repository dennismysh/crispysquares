import XCTest
@testable import CrispySquares

final class PresetTests: XCTestCase {

    func testBuiltInPresetsExist() {
        let builtIn = Preset.builtIn
        XCTAssertEqual(builtIn.count, 4)
        let names = builtIn.map(\.name)
        XCTAssertTrue(names.contains("Bold Text"))
        XCTAssertTrue(names.contains("High Contrast"))
        XCTAssertTrue(names.contains("Warm Reading"))
        XCTAssertTrue(names.contains("sRGB Standard"))
    }

    func testBoldTextPresetLowersGamma() {
        let preset = Preset.builtIn.first { $0.name == "Bold Text" }!
        let table = preset.curve.generateTable(size: 256)
        let standardTable = GammaCurve.parametric(gamma: 2.2).generateTable(size: 256)
        XCTAssertGreaterThan(table[127], standardTable[127])
    }

    func testSRGBStandardIsGamma22() {
        let preset = Preset.builtIn.first { $0.name == "sRGB Standard" }!
        let table = preset.curve.generateTable(size: 256)
        let standardTable = GammaCurve.parametric(gamma: 2.2).generateTable(size: 256)
        for i in 0..<256 {
            XCTAssertEqual(table[i], standardTable[i], accuracy: 0.001)
        }
    }

    func testHighContrastPresetHasContrastBoost() {
        let preset = Preset.builtIn.first { $0.name == "High Contrast" }!
        let table = preset.curve.generateTable(size: 256)
        let flatTable = GammaCurve.parametric(gamma: 2.2).generateTable(size: 256)
        XCTAssertLessThan(table[64], flatTable[64])
        XCTAssertGreaterThan(table[192], flatTable[192])
    }

    func testPresetCodableRoundTrip() throws {
        let original = Preset(name: "Custom", curve: .parametric(gamma: 1.9), isBuiltIn: false)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Preset.self, from: data)
        XCTAssertEqual(decoded.name, "Custom")
        XCTAssertFalse(decoded.isBuiltIn)
    }
}
