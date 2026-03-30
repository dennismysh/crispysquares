import XCTest
@testable import CrispySquares

final class GammaCurveTests: XCTestCase {

    // MARK: - Parametric gamma curve

    func testLinearGammaProducesIdentityTable() {
        let curve = GammaCurve.parametric(gamma: 1.0)
        let table = curve.generateTable(size: 256)
        XCTAssertEqual(table.count, 256)
        XCTAssertEqual(table[0], 0.0, accuracy: 0.001)
        XCTAssertEqual(table[127], 127.0 / 255.0, accuracy: 0.01)
        XCTAssertEqual(table[255], 1.0, accuracy: 0.001)
    }

    func testLowGammaProducesBrighterMidtones() {
        let bold = GammaCurve.parametric(gamma: 1.8)
        let standard = GammaCurve.parametric(gamma: 2.2)
        let boldTable = bold.generateTable(size: 256)
        let standardTable = standard.generateTable(size: 256)
        XCTAssertGreaterThan(boldTable[127], standardTable[127])
        XCTAssertEqual(boldTable[0], 0.0, accuracy: 0.001)
        XCTAssertEqual(boldTable[255], 1.0, accuracy: 0.001)
    }

    func testTableValuesAreMonotonicallyIncreasing() {
        let curve = GammaCurve.parametric(gamma: 1.8)
        let table = curve.generateTable(size: 256)
        for i in 1..<table.count {
            XCTAssertGreaterThanOrEqual(table[i], table[i - 1], "Table not monotonic at index \(i)")
        }
    }

    func testTableValuesClampedToUnitRange() {
        let curve = GammaCurve.parametric(gamma: 0.5)
        let table = curve.generateTable(size: 256)
        for (i, value) in table.enumerated() {
            XCTAssertGreaterThanOrEqual(value, 0.0, "Below 0 at index \(i)")
            XCTAssertLessThanOrEqual(value, 1.0, "Above 1 at index \(i)")
        }
    }

    // MARK: - Black point and white point

    func testBlackPointRaisesMinimum() {
        let curve = GammaCurve.parametric(gamma: 2.2, blackPoint: 0.05, whitePoint: 1.0)
        let table = curve.generateTable(size: 256)
        XCTAssertEqual(table[0], 0.05, accuracy: 0.001)
        XCTAssertEqual(table[255], 1.0, accuracy: 0.001)
    }

    func testWhitePointLowersMaximum() {
        let curve = GammaCurve.parametric(gamma: 2.2, blackPoint: 0.0, whitePoint: 0.9)
        let table = curve.generateTable(size: 256)
        XCTAssertEqual(table[0], 0.0, accuracy: 0.001)
        XCTAssertEqual(table[255], 0.9, accuracy: 0.001)
    }

    // MARK: - Control point curve

    func testControlPointCurveInterpolates() {
        let curve = GammaCurve.controlPoints([
            GammaCurve.ControlPoint(x: 0.0, y: 0.0),
            GammaCurve.ControlPoint(x: 1.0, y: 1.0)
        ])
        let table = curve.generateTable(size: 256)
        XCTAssertEqual(table[127], 127.0 / 255.0, accuracy: 0.02)
    }

    func testControlPointCurveWithMidpointAboveLine() {
        let curve = GammaCurve.controlPoints([
            GammaCurve.ControlPoint(x: 0.0, y: 0.0),
            GammaCurve.ControlPoint(x: 0.5, y: 0.7),
            GammaCurve.ControlPoint(x: 1.0, y: 1.0)
        ])
        let table = curve.generateTable(size: 256)
        XCTAssertEqual(table[127], 0.7, accuracy: 0.05)
    }

    // MARK: - Contrast boost (S-curve)

    func testContrastBoostSteepensMiddle() {
        let flat = GammaCurve.parametric(gamma: 2.2)
        let boosted = GammaCurve.parametric(gamma: 2.2, contrastBoost: 0.3)
        let flatTable = flat.generateTable(size: 256)
        let boostedTable = boosted.generateTable(size: 256)
        XCTAssertLessThan(boostedTable[64], flatTable[64])
        XCTAssertGreaterThan(boostedTable[192], flatTable[192])
    }

    // MARK: - Codable

    func testParametricCurveCodableRoundTrip() throws {
        let original = GammaCurve.parametric(gamma: 1.8, blackPoint: 0.02, whitePoint: 0.98)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GammaCurve.self, from: data)
        let originalTable = original.generateTable(size: 256)
        let decodedTable = decoded.generateTable(size: 256)
        for i in 0..<256 {
            XCTAssertEqual(originalTable[i], decodedTable[i], accuracy: 0.0001, "Mismatch at index \(i)")
        }
    }

    func testControlPointCurveCodableRoundTrip() throws {
        let original = GammaCurve.controlPoints([
            GammaCurve.ControlPoint(x: 0.0, y: 0.0),
            GammaCurve.ControlPoint(x: 0.4, y: 0.6),
            GammaCurve.ControlPoint(x: 1.0, y: 1.0)
        ])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GammaCurve.self, from: data)
        let originalTable = original.generateTable(size: 256)
        let decodedTable = decoded.generateTable(size: 256)
        for i in 0..<256 {
            XCTAssertEqual(originalTable[i], decodedTable[i], accuracy: 0.0001, "Mismatch at index \(i)")
        }
    }
}
