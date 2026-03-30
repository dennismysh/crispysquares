# CrispySquares Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS menu bar utility that improves display rendering on 1080p screens through font smoothing controls, gamma curve editing, and ICC profile management.

**Architecture:** SwiftUI `MenuBarExtra` app with a settings window using `NavigationSplitView`. Three core services (`DisplayManager`, `GammaEngine`, `ConfigStore`) provide display enumeration, gamma table manipulation, and persistence. Modules (Font Smoothing, Gamma & Color, ICC Profiles) are SwiftUI views that consume these services via `@EnvironmentObject`.

**Tech Stack:** Swift 5.9, SwiftUI, AppKit (NSView for curve editor), CoreGraphics (gamma tables), ColorSync (ICC profiles), xcodegen (project generation). macOS 13+ (Ventura). No third-party SPM dependencies.

**Spec:** `docs/superpowers/specs/2026-03-30-crispysquares-design.md`

---

## File Structure

```
Sources/CrispySquares/
├── CrispySquaresApp.swift              # @main, MenuBarExtra, settings window
├── Models/
│   ├── GammaCurve.swift                # Bezier curve model, gamma table generation
│   ├── Preset.swift                    # Built-in and custom presets
│   ├── DisplayInfo.swift               # Display metadata (ID, name, size)
│   └── AppConfig.swift                 # Codable config types for persistence
├── Services/
│   ├── DisplayManager.swift            # Display enumeration, plug/unplug/wake events
│   ├── GammaEngine.swift               # Gamma table R/W, ICC profile creation/install
│   ├── ConfigStore.swift               # JSON file persistence
│   └── FontSmoothingService.swift      # AppleFontSmoothing defaults read/write
└── Views/
    ├── SettingsWindow.swift            # NavigationSplitView with sidebar
    ├── SidebarView.swift               # Sidebar navigation items
    ├── DisplayPicker.swift             # Shared display selector dropdown
    ├── TextPreviewView.swift           # Sample text rendering for preview
    ├── FontSmoothingView.swift         # Font smoothing module controls
    ├── AppOverrideRow.swift            # Per-app font smoothing override row
    ├── GammaColorView.swift            # Gamma & Color module layout
    ├── CurveEditorNSView.swift         # NSView with Core Graphics curve drawing + interaction
    ├── CurveEditorView.swift           # NSViewRepresentable wrapper
    ├── GammaControlsView.swift         # Gamma, contrast, black/white point sliders
    ├── ICCProfilesView.swift           # ICC profile list and actions
    └── ProfileRow.swift                # Single profile row in list

Tests/CrispySquaresTests/
├── GammaCurveTests.swift               # Curve math and table generation
├── PresetTests.swift                   # Preset curve verification
├── ConfigStoreTests.swift              # Serialization round-trips
└── FontSmoothingServiceTests.swift     # Defaults read/write
```

```
project.yml                             # xcodegen project definition
```

---

## Task 1: Project Setup

**Files:**
- Create: `project.yml`
- Create: `Sources/CrispySquares/CrispySquaresApp.swift`
- Create: `Tests/CrispySquaresTests/PlaceholderTests.swift`

- [ ] **Step 1: Install xcodegen**

```bash
brew install xcodegen
```

Expected: xcodegen installed (or already installed).

- [ ] **Step 2: Create project.yml**

Create `project.yml` at the project root:

```yaml
name: CrispySquares
options:
  bundleIdPrefix: com.crispysquares
  deploymentTarget:
    macOS: "13.0"
  createIntermediateGroups: true
  generateEmptyDirectories: true
targets:
  CrispySquares:
    type: application
    platform: macOS
    sources:
      - path: Sources/CrispySquares
    info:
      properties:
        LSUIElement: true
        CFBundleDisplayName: CrispySquares
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.crispysquares.app
        MACOSX_DEPLOYMENT_TARGET: "13.0"
        SWIFT_VERSION: "5.9"
        CODE_SIGN_IDENTITY: "-"
        CODE_SIGN_STYLE: Manual
    scheme:
      testTargets:
        - CrispySquaresTests
  CrispySquaresTests:
    type: bundle.unit-test
    platform: macOS
    sources:
      - path: Tests/CrispySquaresTests
    dependencies:
      - target: CrispySquares
    settings:
      base:
        BUNDLE_LOADER: "$(TEST_HOST)"
        TEST_HOST: "$(BUILT_PRODUCTS_DIR)/CrispySquares.app/Contents/MacOS/CrispySquares"
```

- [ ] **Step 3: Create app entry point**

Create `Sources/CrispySquares/CrispySquaresApp.swift`:

```swift
import SwiftUI

@main
struct CrispySquaresApp: App {
    var body: some Scene {
        MenuBarExtra("CrispySquares", systemImage: "display") {
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
```

- [ ] **Step 4: Create placeholder test**

Create `Tests/CrispySquaresTests/PlaceholderTests.swift`:

```swift
import XCTest
@testable import CrispySquares

final class PlaceholderTests: XCTestCase {
    func testAppLaunches() {
        XCTAssertTrue(true)
    }
}
```

- [ ] **Step 5: Generate Xcode project and build**

```bash
cd "/Users/dennis/programming projects/antialiasing" && xcodegen generate
```

Expected: `CrispySquares.xcodeproj` created.

```bash
xcodebuild build -project CrispySquares.xcodeproj -scheme CrispySquares -destination 'platform=macOS' -derivedDataPath .build 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 6: Run tests**

```bash
xcodebuild test -project CrispySquares.xcodeproj -scheme CrispySquares -destination 'platform=macOS' -derivedDataPath .build 2>&1 | tail -10
```

Expected: `Test Suite 'All tests' passed`

- [ ] **Step 7: Update .gitignore and commit**

Append to `.gitignore`:

```
CrispySquares.xcodeproj/
.build/
```

```bash
git add project.yml Sources/ Tests/ .gitignore
git commit -m "feat: project setup with xcodegen, MenuBarExtra skeleton, and test target"
```

---

## Task 2: GammaCurve Model (TDD)

**Files:**
- Create: `Sources/CrispySquares/Models/GammaCurve.swift`
- Create: `Tests/CrispySquaresTests/GammaCurveTests.swift`
- Delete: `Tests/CrispySquaresTests/PlaceholderTests.swift`

- [ ] **Step 1: Write failing tests for GammaCurve**

Create `Tests/CrispySquaresTests/GammaCurveTests.swift`:

```swift
import XCTest
@testable import CrispySquares

final class GammaCurveTests: XCTestCase {

    // MARK: - Parametric gamma curve

    func testLinearGammaProducesIdentityTable() {
        // gamma = 1.0 means y = x^(1/1) = x (identity)
        let curve = GammaCurve.parametric(gamma: 1.0)
        let table = curve.generateTable(size: 256)

        XCTAssertEqual(table.count, 256)
        XCTAssertEqual(table[0], 0.0, accuracy: 0.001)
        XCTAssertEqual(table[127], 127.0 / 255.0, accuracy: 0.01)
        XCTAssertEqual(table[255], 1.0, accuracy: 0.001)
    }

    func testLowGammaProducesBrighterMidtones() {
        // gamma 1.8 should produce brighter midtones than gamma 2.2
        let bold = GammaCurve.parametric(gamma: 1.8)
        let standard = GammaCurve.parametric(gamma: 2.2)

        let boldTable = bold.generateTable(size: 256)
        let standardTable = standard.generateTable(size: 256)

        // Midpoint (x=0.5) should be brighter with lower gamma
        XCTAssertGreaterThan(boldTable[127], standardTable[127])
        // Endpoints should be the same
        XCTAssertEqual(boldTable[0], 0.0, accuracy: 0.001)
        XCTAssertEqual(boldTable[255], 1.0, accuracy: 0.001)
    }

    func testTableValuesAreMonotonicallyIncreasing() {
        let curve = GammaCurve.parametric(gamma: 1.8)
        let table = curve.generateTable(size: 256)

        for i in 1..<table.count {
            XCTAssertGreaterThanOrEqual(table[i], table[i - 1],
                "Table not monotonic at index \(i)")
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
        // Two control points defining a straight line from (0,0) to (1,1)
        let curve = GammaCurve.controlPoints([
            GammaCurve.ControlPoint(x: 0.0, y: 0.0),
            GammaCurve.ControlPoint(x: 1.0, y: 1.0)
        ])
        let table = curve.generateTable(size: 256)

        // Should be approximately linear
        XCTAssertEqual(table[127], 127.0 / 255.0, accuracy: 0.02)
    }

    func testControlPointCurveWithMidpointAboveLine() {
        // Midpoint pulled up — brighter midtones (like lowering gamma)
        let curve = GammaCurve.controlPoints([
            GammaCurve.ControlPoint(x: 0.0, y: 0.0),
            GammaCurve.ControlPoint(x: 0.5, y: 0.7),
            GammaCurve.ControlPoint(x: 1.0, y: 1.0)
        ])
        let table = curve.generateTable(size: 256)

        // At x=0.5, y should be approximately 0.7
        XCTAssertEqual(table[127], 0.7, accuracy: 0.05)
    }

    // MARK: - Contrast boost (S-curve)

    func testContrastBoostSteepensMiddle() {
        let flat = GammaCurve.parametric(gamma: 2.2)
        let boosted = GammaCurve.parametric(gamma: 2.2, contrastBoost: 0.3)

        let flatTable = flat.generateTable(size: 256)
        let boostedTable = boosted.generateTable(size: 256)

        // Dark values should be darker with contrast boost
        XCTAssertLessThan(boostedTable[64], flatTable[64])
        // Bright values should be brighter with contrast boost
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
            XCTAssertEqual(originalTable[i], decodedTable[i], accuracy: 0.0001,
                "Mismatch at index \(i)")
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
            XCTAssertEqual(originalTable[i], decodedTable[i], accuracy: 0.0001,
                "Mismatch at index \(i)")
        }
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodegen generate && xcodebuild test -project CrispySquares.xcodeproj -scheme CrispySquares -destination 'platform=macOS' -derivedDataPath .build 2>&1 | grep -E "(FAIL|error:|BUILD)"
```

Expected: Compilation errors — `GammaCurve` not defined.

- [ ] **Step 3: Implement GammaCurve**

Create `Sources/CrispySquares/Models/GammaCurve.swift`:

```swift
import Foundation

struct GammaCurve: Codable, Equatable {

    struct ControlPoint: Codable, Equatable {
        let x: Float
        let y: Float
    }

    enum CurveType: Codable, Equatable {
        case parametric(gamma: Float, blackPoint: Float, whitePoint: Float, contrastBoost: Float)
        case controlPoints([ControlPoint])
    }

    let curveType: CurveType

    // MARK: - Factories

    static func parametric(
        gamma: Float,
        blackPoint: Float = 0.0,
        whitePoint: Float = 1.0,
        contrastBoost: Float = 0.0
    ) -> GammaCurve {
        GammaCurve(curveType: .parametric(
            gamma: gamma,
            blackPoint: blackPoint,
            whitePoint: whitePoint,
            contrastBoost: contrastBoost
        ))
    }

    static func controlPoints(_ points: [ControlPoint]) -> GammaCurve {
        GammaCurve(curveType: .controlPoints(points))
    }

    // MARK: - Table Generation

    func generateTable(size: Int) -> [Float] {
        (0..<size).map { i in
            let x = Float(i) / Float(size - 1)
            let y = evaluate(at: x)
            return min(max(y, 0.0), 1.0)
        }
    }

    func evaluate(at x: Float) -> Float {
        switch curveType {
        case let .parametric(gamma, blackPoint, whitePoint, contrastBoost):
            return evaluateParametric(x: x, gamma: gamma, blackPoint: blackPoint,
                                      whitePoint: whitePoint, contrastBoost: contrastBoost)
        case let .controlPoints(points):
            return evaluateControlPoints(x: x, points: points)
        }
    }

    // MARK: - Parametric

    private func evaluateParametric(
        x: Float, gamma: Float, blackPoint: Float, whitePoint: Float, contrastBoost: Float
    ) -> Float {
        // Apply gamma: y = x^(1/gamma)
        var y = powf(x, 1.0 / gamma)

        // Apply S-curve contrast boost
        if contrastBoost > 0 {
            y = applySCurve(y, strength: contrastBoost)
        }

        // Map to [blackPoint, whitePoint]
        return blackPoint + y * (whitePoint - blackPoint)
    }

    private func applySCurve(_ x: Float, strength: Float) -> Float {
        // Attempt with a smooth S-curve using adjusted power curve
        // strength 0..1 controls how much contrast is added
        let k = 1.0 + strength * 4.0  // k from 1 (no effect) to 5 (strong)
        if x < 0.5 {
            return 0.5 * powf(2.0 * x, k)
        } else {
            return 1.0 - 0.5 * powf(2.0 * (1.0 - x), k)
        }
    }

    // MARK: - Control Points (Monotone Cubic Interpolation)

    private func evaluateControlPoints(x: Float, points: [ControlPoint]) -> Float {
        guard points.count >= 2 else { return x }

        let sorted = points.sorted { $0.x < $1.x }

        // Clamp to endpoints
        if x <= sorted.first!.x { return sorted.first!.y }
        if x >= sorted.last!.x { return sorted.last!.y }

        // Find the segment
        var segIndex = 0
        for i in 0..<(sorted.count - 1) {
            if x >= sorted[i].x && x <= sorted[i + 1].x {
                segIndex = i
                break
            }
        }

        let p0 = sorted[segIndex]
        let p1 = sorted[segIndex + 1]

        // Linear interpolation for segments between adjacent control points
        // For more control points, use Catmull-Rom or monotone Hermite
        if sorted.count == 2 {
            let t = (x - p0.x) / (p1.x - p0.x)
            return p0.y + t * (p1.y - p0.y)
        }

        // Monotone cubic Hermite interpolation (Fritsch-Carlson)
        let t = (x - p0.x) / (p1.x - p0.x)
        let m0 = tangent(at: segIndex, points: sorted)
        let m1 = tangent(at: segIndex + 1, points: sorted)

        let dx = p1.x - p0.x
        let t2 = t * t
        let t3 = t2 * t

        let h00 = 2 * t3 - 3 * t2 + 1
        let h10 = t3 - 2 * t2 + t
        let h01 = -2 * t3 + 3 * t2
        let h11 = t3 - t2

        return h00 * p0.y + h10 * dx * m0 + h01 * p1.y + h11 * dx * m1
    }

    private func tangent(at index: Int, points: [ControlPoint]) -> Float {
        if index == 0 {
            return (points[1].y - points[0].y) / (points[1].x - points[0].x)
        }
        if index == points.count - 1 {
            let last = points.count - 1
            return (points[last].y - points[last - 1].y) / (points[last].x - points[last - 1].x)
        }
        let d0 = (points[index].y - points[index - 1].y) / (points[index].x - points[index - 1].x)
        let d1 = (points[index + 1].y - points[index].y) / (points[index + 1].x - points[index].x)
        return (d0 + d1) / 2.0
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
xcodegen generate && xcodebuild test -project CrispySquares.xcodeproj -scheme CrispySquares -destination 'platform=macOS' -derivedDataPath .build -only-testing CrispySquaresTests/GammaCurveTests 2>&1 | tail -15
```

Expected: All tests pass.

- [ ] **Step 5: Delete placeholder test and commit**

Delete `Tests/CrispySquaresTests/PlaceholderTests.swift`.

```bash
git add Sources/CrispySquares/Models/GammaCurve.swift Tests/CrispySquaresTests/GammaCurveTests.swift
git rm Tests/CrispySquaresTests/PlaceholderTests.swift
git commit -m "feat: GammaCurve model with parametric, control point, and S-curve support"
```

---

## Task 3: Preset Model (TDD)

**Files:**
- Create: `Sources/CrispySquares/Models/Preset.swift`
- Create: `Tests/CrispySquaresTests/PresetTests.swift`

- [ ] **Step 1: Write failing tests**

Create `Tests/CrispySquaresTests/PresetTests.swift`:

```swift
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

        // Midtones should be brighter than standard 2.2
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

        // Dark values darker, bright values brighter
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
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodegen generate && xcodebuild test -project CrispySquares.xcodeproj -scheme CrispySquares -destination 'platform=macOS' -derivedDataPath .build -only-testing CrispySquaresTests/PresetTests 2>&1 | grep -E "(error:|FAIL|BUILD)"
```

Expected: Compilation error — `Preset` not defined.

- [ ] **Step 3: Implement Preset**

Create `Sources/CrispySquares/Models/Preset.swift`:

```swift
import Foundation

struct Preset: Codable, Identifiable {
    let id: UUID
    let name: String
    let curve: GammaCurve
    let isBuiltIn: Bool

    init(name: String, curve: GammaCurve, isBuiltIn: Bool, id: UUID = UUID()) {
        self.id = id
        self.name = name
        self.curve = curve
        self.isBuiltIn = isBuiltIn
    }

    static let builtIn: [Preset] = [
        Preset(
            name: "Bold Text",
            curve: .parametric(gamma: 1.8),
            isBuiltIn: true
        ),
        Preset(
            name: "High Contrast",
            curve: .parametric(gamma: 2.2, contrastBoost: 0.3),
            isBuiltIn: true
        ),
        Preset(
            name: "Warm Reading",
            curve: .parametric(gamma: 1.9),
            isBuiltIn: true
        ),
        Preset(
            name: "sRGB Standard",
            curve: .parametric(gamma: 2.2),
            isBuiltIn: true
        ),
    ]
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
xcodegen generate && xcodebuild test -project CrispySquares.xcodeproj -scheme CrispySquares -destination 'platform=macOS' -derivedDataPath .build -only-testing CrispySquaresTests/PresetTests 2>&1 | tail -15
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add Sources/CrispySquares/Models/Preset.swift Tests/CrispySquaresTests/PresetTests.swift
git commit -m "feat: Preset model with 4 built-in presets"
```

---

## Task 4: AppConfig & ConfigStore (TDD)

**Files:**
- Create: `Sources/CrispySquares/Models/AppConfig.swift`
- Create: `Sources/CrispySquares/Services/ConfigStore.swift`
- Create: `Tests/CrispySquaresTests/ConfigStoreTests.swift`

- [ ] **Step 1: Write failing tests**

Create `Tests/CrispySquaresTests/ConfigStoreTests.swift`:

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodegen generate && xcodebuild test -project CrispySquares.xcodeproj -scheme CrispySquares -destination 'platform=macOS' -derivedDataPath .build -only-testing CrispySquaresTests/ConfigStoreTests 2>&1 | grep -E "(error:|FAIL|BUILD)"
```

Expected: Compilation errors — `AppConfig`, `ConfigStore`, `DisplaySettings` not defined.

- [ ] **Step 3: Implement AppConfig**

Create `Sources/CrispySquares/Models/AppConfig.swift`:

```swift
import Foundation

struct DisplaySettings: Codable, Equatable {
    var gammaCurve: GammaCurve
    var profileName: String?
}

struct AppConfig: Codable {
    var globalFontSmoothing: Int?
    var displaySettings: [String: DisplaySettings] = [:]
    var appOverrides: [String: Int] = [:]
    var customPresets: [Preset] = []
    var launchAtLogin: Bool = false
}
```

- [ ] **Step 4: Implement ConfigStore**

Create `Sources/CrispySquares/Services/ConfigStore.swift`:

```swift
import Foundation

final class ConfigStore {
    private let configURL: URL

    init(directory: URL) {
        self.configURL = directory.appendingPathComponent("config.json")
    }

    convenience init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("CrispySquares")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.init(directory: dir)
    }

    func save(_ config: AppConfig) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: configURL, options: .atomic)
    }

    func load() throws -> AppConfig {
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            return AppConfig()
        }
        let data = try Data(contentsOf: configURL)
        return try JSONDecoder().decode(AppConfig.self, from: data)
    }
}
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
xcodegen generate && xcodebuild test -project CrispySquares.xcodeproj -scheme CrispySquares -destination 'platform=macOS' -derivedDataPath .build -only-testing CrispySquaresTests/ConfigStoreTests 2>&1 | tail -15
```

Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add Sources/CrispySquares/Models/AppConfig.swift Sources/CrispySquares/Services/ConfigStore.swift Tests/CrispySquaresTests/ConfigStoreTests.swift
git commit -m "feat: AppConfig model and ConfigStore with JSON persistence"
```

---

## Task 5: DisplayManager Service

**Files:**
- Create: `Sources/CrispySquares/Models/DisplayInfo.swift`
- Create: `Sources/CrispySquares/Services/DisplayManager.swift`

- [ ] **Step 1: Create DisplayInfo model**

Create `Sources/CrispySquares/Models/DisplayInfo.swift`:

```swift
import Foundation
import CoreGraphics

struct DisplayInfo: Identifiable, Equatable {
    let id: CGDirectDisplayID
    let name: String
    let width: Int
    let height: Int
    let isBuiltIn: Bool

    var displayKey: String {
        String(id)
    }

    static func from(displayID: CGDirectDisplayID) -> DisplayInfo {
        let width = CGDisplayPixelsWide(displayID)
        let height = CGDisplayPixelsHigh(displayID)
        let isBuiltIn = CGDisplayIsBuiltin(displayID) != 0

        let name: String
        if isBuiltIn {
            name = "Built-in Display"
        } else {
            // CGDisplayModelNumber gives a numeric ID; use a generic name
            let model = CGDisplayModelNumber(displayID)
            let vendor = CGDisplayVendorNumber(displayID)
            name = "Display \(vendor)-\(model)"
        }

        return DisplayInfo(
            id: displayID,
            name: name,
            width: width,
            height: height,
            isBuiltIn: isBuiltIn
        )
    }
}
```

- [ ] **Step 2: Implement DisplayManager**

Create `Sources/CrispySquares/Services/DisplayManager.swift`:

```swift
import Foundation
import Combine
import AppKit
import CoreGraphics

final class DisplayManager: ObservableObject {
    @Published var displays: [DisplayInfo] = []
    @Published var selectedDisplayID: CGDirectDisplayID?

    private var reconfigurationToken: AnyObject?

    init() {
        refreshDisplays()
        registerForDisplayChanges()
        registerForWakeNotifications()
    }

    deinit {
        if let token = reconfigurationToken {
            // CGDisplayRemoveReconfigurationCallback is global, handled separately
            NotificationCenter.default.removeObserver(token)
        }
    }

    var selectedDisplay: DisplayInfo? {
        guard let id = selectedDisplayID else { return displays.first }
        return displays.first { $0.id == id }
    }

    func refreshDisplays() {
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: 16)
        var displayCount: UInt32 = 0

        let err = CGGetActiveDisplayList(16, &displayIDs, &displayCount)
        guard err == .success else { return }

        let newDisplays = (0..<Int(displayCount)).map { i in
            DisplayInfo.from(displayID: displayIDs[i])
        }

        DispatchQueue.main.async {
            self.displays = newDisplays
            // Keep selection valid
            if let selected = self.selectedDisplayID,
               !newDisplays.contains(where: { $0.id == selected }) {
                self.selectedDisplayID = newDisplays.first?.id
            }
            if self.selectedDisplayID == nil {
                self.selectedDisplayID = newDisplays.first?.id
            }
        }
    }

    private func registerForDisplayChanges() {
        CGDisplayRegisterReconfigurationCallback({ displayID, flags, userInfo in
            guard let manager = userInfo.map({ Unmanaged<DisplayManager>.fromOpaque($0).takeUnretainedValue() }) else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                manager.refreshDisplays()
            }
        }, Unmanaged.passUnretained(self).toOpaque())
    }

    private func registerForWakeNotifications() {
        reconfigurationToken = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.refreshDisplays()
            }
        }
    }
}
```

- [ ] **Step 3: Build to verify compilation**

```bash
xcodegen generate && xcodebuild build -project CrispySquares.xcodeproj -scheme CrispySquares -destination 'platform=macOS' -derivedDataPath .build 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add Sources/CrispySquares/Models/DisplayInfo.swift Sources/CrispySquares/Services/DisplayManager.swift
git commit -m "feat: DisplayManager with display enumeration and change notifications"
```

---

## Task 6: GammaEngine Service

**Files:**
- Create: `Sources/CrispySquares/Services/GammaEngine.swift`

- [ ] **Step 1: Implement GammaEngine**

Create `Sources/CrispySquares/Services/GammaEngine.swift`:

```swift
import Foundation
import CoreGraphics

final class GammaEngine: ObservableObject {
    @Published var isLivePreviewing = false

    private var previewTimer: Timer?
    private var savedCurveBeforePreview: GammaCurve?

    // MARK: - Gamma Table Operations

    func applyGammaTable(curve: GammaCurve, to displayID: CGDirectDisplayID) {
        let table = curve.generateTable(size: 256)
        table.withUnsafeBufferPointer { buffer in
            guard let ptr = buffer.baseAddress else { return }
            CGSetDisplayTransferByTable(displayID, 256, ptr, ptr, ptr)
        }
    }

    func applyPerChannelGammaTables(
        red: GammaCurve, green: GammaCurve, blue: GammaCurve,
        to displayID: CGDirectDisplayID
    ) {
        let redTable = red.generateTable(size: 256)
        let greenTable = green.generateTable(size: 256)
        let blueTable = blue.generateTable(size: 256)

        redTable.withUnsafeBufferPointer { rBuf in
            greenTable.withUnsafeBufferPointer { gBuf in
                blueTable.withUnsafeBufferPointer { bBuf in
                    guard let rPtr = rBuf.baseAddress,
                          let gPtr = gBuf.baseAddress,
                          let bPtr = bBuf.baseAddress else { return }
                    CGSetDisplayTransferByTable(displayID, 256, rPtr, gPtr, bPtr)
                }
            }
        }
    }

    func readCurrentGammaTable(for displayID: CGDirectDisplayID) -> (red: [Float], green: [Float], blue: [Float])? {
        var red = [Float](repeating: 0, count: 256)
        var green = [Float](repeating: 0, count: 256)
        var blue = [Float](repeating: 0, count: 256)
        var sampleCount: UInt32 = 0

        let err = CGGetDisplayTransferByTable(displayID, 256, &red, &green, &blue, &sampleCount)
        guard err == .success else { return nil }

        return (
            red: Array(red.prefix(Int(sampleCount))),
            green: Array(green.prefix(Int(sampleCount))),
            blue: Array(blue.prefix(Int(sampleCount)))
        )
    }

    // MARK: - Live Preview

    func startPreview(curve: GammaCurve, on displayID: CGDirectDisplayID) {
        isLivePreviewing = true
        applyGammaTable(curve: curve, to: displayID)
    }

    func updatePreview(curve: GammaCurve, on displayID: CGDirectDisplayID) {
        guard isLivePreviewing else { return }
        applyGammaTable(curve: curve, to: displayID)
    }

    func cancelPreview(on displayID: CGDirectDisplayID) {
        isLivePreviewing = false
        resetDisplay(displayID)
    }

    // MARK: - Reset

    func resetDisplay(_ displayID: CGDirectDisplayID) {
        CGDisplayRestoreColorSyncSettings()
    }

    func resetAllDisplays() {
        CGDisplayRestoreColorSyncSettings()
    }

    // MARK: - ICC Profile Generation

    func saveAsICCProfile(curve: GammaCurve, name: String) throws -> URL {
        let table = curve.generateTable(size: 256)
        let profileData = buildICCProfile(redTable: table, greenTable: table, blueTable: table, description: name)

        let profilesDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/ColorSync/Profiles")
        try FileManager.default.createDirectory(at: profilesDir, withIntermediateDirectories: true)

        let fileName = "CrispySquares-\(name.replacingOccurrences(of: " ", with: "-")).icc"
        let url = profilesDir.appendingPathComponent(fileName)
        try profileData.write(to: url)
        return url
    }

    func assignProfile(at url: URL, to displayID: CGDirectDisplayID) -> Bool {
        guard let profile = ColorSyncProfileCreateWithURL(url as CFURL, nil)?.takeRetainedValue() else {
            return false
        }

        let deviceID = ColorSyncDeviceID(rawValue: CGDisplayCreateUUIDFromDisplayID(displayID).takeRetainedValue())

        let profileInfo: [String: Any] = [
            kColorSyncDeviceDefaultProfileID.takeUnretainedValue() as String: profile
        ]

        return ColorSyncDeviceSetCustomProfiles(
            kColorSyncDisplayDeviceClass.takeUnretainedValue(),
            deviceID,
            profileInfo as CFDictionary
        )
    }

    // MARK: - ICC Binary Construction

    private func buildICCProfile(redTable: [Float], greenTable: [Float], blueTable: [Float], description: String) -> Data {
        var data = Data()

        // Profile header (128 bytes)
        var header = Data(count: 128)
        // Profile size — will be filled at the end
        // Preferred CMM: 'appl'
        header.replaceSubrange(4..<8, with: "appl".data(using: .ascii)!)
        // Version 2.1.0
        header[8] = 0x02; header[9] = 0x10
        // Device class: 'mntr' (monitor)
        header.replaceSubrange(12..<16, with: "mntr".data(using: .ascii)!)
        // Color space: 'RGB '
        header.replaceSubrange(16..<20, with: "RGB ".data(using: .ascii)!)
        // PCS: 'XYZ '
        header.replaceSubrange(20..<24, with: "XYZ ".data(using: .ascii)!)
        // Date/time: current
        let now = Date()
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        writeUInt16(&header, offset: 24, value: UInt16(components.year!))
        writeUInt16(&header, offset: 26, value: UInt16(components.month!))
        writeUInt16(&header, offset: 28, value: UInt16(components.day!))
        writeUInt16(&header, offset: 30, value: UInt16(components.hour!))
        writeUInt16(&header, offset: 32, value: UInt16(components.minute!))
        writeUInt16(&header, offset: 34, value: UInt16(components.second!))
        // Signature: 'acsp'
        header.replaceSubrange(36..<40, with: "acsp".data(using: .ascii)!)
        // Primary platform: 'APPL'
        header.replaceSubrange(40..<44, with: "APPL".data(using: .ascii)!)
        // Rendering intent: perceptual (0)
        // D50 illuminant: X=0.9642, Y=1.0000, Z=0.8249 as s15Fixed16
        writeS15Fixed16(&header, offset: 68, value: 0.9642)
        writeS15Fixed16(&header, offset: 72, value: 1.0000)
        writeS15Fixed16(&header, offset: 76, value: 0.8249)

        data.append(header)

        // Tag table: 9 tags
        let tagCount: UInt32 = 9
        var tagTable = Data()
        writeUInt32(&tagTable, value: tagCount)

        // We'll compute offsets as we go. Tags start after header (128) + tag table (4 + 9*12 = 112) = 240
        var tagOffset: UInt32 = 128 + 4 + tagCount * 12
        var tagData = Data()

        // Build each tag's data and record its position
        struct TagEntry {
            let sig: String
            let data: Data
        }

        // sRGB D65 matrix columns (from sRGB spec)
        let redX: Float = 0.4124, redY: Float = 0.2126, redZ: Float = 0.0193
        let greenX: Float = 0.3576, greenY: Float = 0.7152, greenZ: Float = 0.1192
        let blueX: Float = 0.1805, blueY: Float = 0.0722, blueZ: Float = 0.9505

        let tags: [TagEntry] = [
            TagEntry(sig: "desc", data: buildTextDescriptionTag(description)),
            TagEntry(sig: "wtpt", data: buildXYZTag(x: 0.9505, y: 1.0, z: 1.0890)),
            TagEntry(sig: "rXYZ", data: buildXYZTag(x: redX, y: redY, z: redZ)),
            TagEntry(sig: "gXYZ", data: buildXYZTag(x: greenX, y: greenY, z: greenZ)),
            TagEntry(sig: "bXYZ", data: buildXYZTag(x: blueX, y: blueY, z: blueZ)),
            TagEntry(sig: "rTRC", data: buildCurveTag(redTable)),
            TagEntry(sig: "gTRC", data: buildCurveTag(greenTable)),
            TagEntry(sig: "bTRC", data: buildCurveTag(blueTable)),
            TagEntry(sig: "cprt", data: buildTextDescriptionTag("CrispySquares")),
        ]

        for tag in tags {
            // Pad tag data to 4-byte boundary
            var paddedData = tag.data
            while paddedData.count % 4 != 0 {
                paddedData.append(0)
            }

            // Tag table entry: signature(4) + offset(4) + size(4)
            tagTable.append(tag.sig.data(using: .ascii)!)
            var offsetBytes = Data(count: 4)
            writeUInt32(&offsetBytes, offset: 0, value: tagOffset)
            tagTable.append(offsetBytes)
            var sizeBytes = Data(count: 4)
            writeUInt32(&sizeBytes, offset: 0, value: UInt32(tag.data.count))
            tagTable.append(sizeBytes)

            tagData.append(paddedData)
            tagOffset += UInt32(paddedData.count)
        }

        data.append(tagTable)
        data.append(tagData)

        // Write total profile size into header
        let totalSize = UInt32(data.count)
        var sizeBytes = Data(count: 4)
        writeUInt32(&sizeBytes, offset: 0, value: totalSize)
        data.replaceSubrange(0..<4, with: sizeBytes)

        return data
    }

    private func buildTextDescriptionTag(_ text: String) -> Data {
        // 'desc' tag type
        var data = Data()
        data.append("desc".data(using: .ascii)!)
        data.append(Data(count: 4)) // reserved
        let ascii = text.data(using: .ascii) ?? Data()
        var lenBytes = Data(count: 4)
        writeUInt32(&lenBytes, offset: 0, value: UInt32(ascii.count + 1))
        data.append(lenBytes)
        data.append(ascii)
        data.append(0) // null terminator
        // Unicode and ScriptCode sections (empty)
        data.append(Data(count: 4)) // Unicode language code
        data.append(Data(count: 4)) // Unicode count
        data.append(Data(count: 3)) // ScriptCode code, count, string
        return data
    }

    private func buildXYZTag(x: Float, y: Float, z: Float) -> Data {
        var data = Data()
        data.append("XYZ ".data(using: .ascii)!)
        data.append(Data(count: 4)) // reserved
        appendS15Fixed16(&data, value: x)
        appendS15Fixed16(&data, value: y)
        appendS15Fixed16(&data, value: z)
        return data
    }

    private func buildCurveTag(_ table: [Float]) -> Data {
        var data = Data()
        data.append("curv".data(using: .ascii)!)
        data.append(Data(count: 4)) // reserved
        var countBytes = Data(count: 4)
        writeUInt32(&countBytes, offset: 0, value: UInt32(table.count))
        data.append(countBytes)
        for value in table {
            let uint16Val = UInt16(min(max(value, 0), 1) * 65535)
            var bytes = Data(count: 2)
            writeUInt16(&bytes, offset: 0, value: uint16Val)
            data.append(bytes)
        }
        return data
    }

    // MARK: - Binary Helpers

    private func writeUInt32(_ data: inout Data, offset: Int = -1, value: UInt32) {
        let bytes = withUnsafeBytes(of: value.bigEndian) { Data($0) }
        if offset >= 0 {
            data.replaceSubrange(offset..<(offset + 4), with: bytes)
        } else {
            data.append(bytes)
        }
    }

    private func writeUInt16(_ data: inout Data, offset: Int, value: UInt16) {
        let bytes = withUnsafeBytes(of: value.bigEndian) { Data($0) }
        data.replaceSubrange(offset..<(offset + 2), with: bytes)
    }

    private func writeS15Fixed16(_ data: inout Data, offset: Int, value: Float) {
        let fixed = Int32(value * 65536.0)
        let bytes = withUnsafeBytes(of: fixed.bigEndian) { Data($0) }
        data.replaceSubrange(offset..<(offset + 4), with: bytes)
    }

    private func appendS15Fixed16(_ data: inout Data, value: Float) {
        let fixed = Int32(value * 65536.0)
        let bytes = withUnsafeBytes(of: fixed.bigEndian) { Data($0) }
        data.append(bytes)
    }
}
```

- [ ] **Step 2: Build to verify compilation**

```bash
xcodegen generate && xcodebuild build -project CrispySquares.xcodeproj -scheme CrispySquares -destination 'platform=macOS' -derivedDataPath .build 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED`. Note: `ColorSyncDeviceSetCustomProfiles` may need `import ColorSync` or linking. If build fails on ColorSync types, add `import ColorSync` at the top and verify the framework is linked by adding it to the project.yml target's `dependencies` or `framework` setting.

- [ ] **Step 3: Commit**

```bash
git add Sources/CrispySquares/Services/GammaEngine.swift
git commit -m "feat: GammaEngine with gamma table R/W, ICC profile generation, and live preview"
```

---

## Task 7: FontSmoothingService (TDD)

**Files:**
- Create: `Sources/CrispySquares/Services/FontSmoothingService.swift`
- Create: `Tests/CrispySquaresTests/FontSmoothingServiceTests.swift`

- [ ] **Step 1: Write failing tests**

Create `Tests/CrispySquaresTests/FontSmoothingServiceTests.swift`:

```swift
import XCTest
@testable import CrispySquares

final class FontSmoothingServiceTests: XCTestCase {

    var service: FontSmoothingService!

    override func setUp() {
        super.setUp()
        service = FontSmoothingService()
    }

    func testReadGlobalFontSmoothing() {
        // Should return an Int? — nil means system default
        let value = service.globalFontSmoothing
        // Value is whatever the current system has; just verify it doesn't crash
        XCTAssertTrue(value == nil || (0...3).contains(value!))
    }

    func testSetAndReadGlobalFontSmoothing() {
        let originalValue = service.globalFontSmoothing

        service.globalFontSmoothing = 2
        XCTAssertEqual(service.globalFontSmoothing, 2)

        // Restore original
        if let orig = originalValue {
            service.globalFontSmoothing = orig
        } else {
            service.removeGlobalFontSmoothing()
        }
    }

    func testListInstalledApps() {
        let apps = service.installedApps()
        // Should find at least some apps in /Applications
        XCTAssertFalse(apps.isEmpty)
        // Each app should have a bundle identifier
        for app in apps {
            XCTAssertFalse(app.bundleIdentifier.isEmpty)
            XCTAssertFalse(app.name.isEmpty)
        }
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodegen generate && xcodebuild test -project CrispySquares.xcodeproj -scheme CrispySquares -destination 'platform=macOS' -derivedDataPath .build -only-testing CrispySquaresTests/FontSmoothingServiceTests 2>&1 | grep -E "(error:|FAIL|BUILD)"
```

Expected: Compilation error — `FontSmoothingService` not defined.

- [ ] **Step 3: Implement FontSmoothingService**

Create `Sources/CrispySquares/Services/FontSmoothingService.swift`:

```swift
import Foundation
import AppKit

struct AppInfo: Identifiable {
    let id: String
    let bundleIdentifier: String
    let name: String
    let icon: NSImage?

    init(bundleIdentifier: String, name: String, icon: NSImage? = nil) {
        self.id = bundleIdentifier
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.icon = icon
    }
}

final class FontSmoothingService: ObservableObject {

    private let globalDomain = UserDefaults(suiteName: UserDefaults.globalDomain)
    private let fontSmoothingKey = "AppleFontSmoothing"

    // MARK: - Global Font Smoothing

    var globalFontSmoothing: Int? {
        get {
            guard let defaults = globalDomain else { return nil }
            let obj = defaults.object(forKey: fontSmoothingKey)
            return obj as? Int
        }
        set {
            if let value = newValue {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
                task.arguments = ["write", "-g", fontSmoothingKey, "-int", String(value)]
                try? task.run()
                task.waitUntilExit()
            }
        }
    }

    func removeGlobalFontSmoothing() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        task.arguments = ["delete", "-g", fontSmoothingKey]
        try? task.run()
        task.waitUntilExit()
    }

    // MARK: - Per-App Overrides

    func fontSmoothing(for bundleID: String) -> Int? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        task.arguments = ["read", bundleID, fontSmoothingKey]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        try? task.run()
        task.waitUntilExit()

        guard task.terminationStatus == 0 else { return nil }
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return output.flatMap(Int.init)
    }

    func setFontSmoothing(_ value: Int, for bundleID: String) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        task.arguments = ["write", bundleID, fontSmoothingKey, "-int", String(value)]
        try? task.run()
        task.waitUntilExit()
    }

    func removeFontSmoothing(for bundleID: String) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        task.arguments = ["delete", bundleID, fontSmoothingKey]
        try? task.run()
        task.waitUntilExit()
    }

    // MARK: - App Discovery

    func installedApps() -> [AppInfo] {
        let appDirs = ["/Applications", "/System/Applications"]
        var apps: [AppInfo] = []

        for dir in appDirs {
            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: URL(fileURLWithPath: dir),
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else { continue }

            for url in contents where url.pathExtension == "app" {
                guard let bundle = Bundle(url: url),
                      let bundleID = bundle.bundleIdentifier else { continue }

                let name = bundle.infoDictionary?["CFBundleDisplayName"] as? String
                    ?? bundle.infoDictionary?["CFBundleName"] as? String
                    ?? url.deletingPathExtension().lastPathComponent

                let icon = NSWorkspace.shared.icon(forFile: url.path)

                apps.append(AppInfo(bundleIdentifier: bundleID, name: name, icon: icon))
            }
        }

        return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
xcodegen generate && xcodebuild test -project CrispySquares.xcodeproj -scheme CrispySquares -destination 'platform=macOS' -derivedDataPath .build -only-testing CrispySquaresTests/FontSmoothingServiceTests 2>&1 | tail -15
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add Sources/CrispySquares/Services/FontSmoothingService.swift Tests/CrispySquaresTests/FontSmoothingServiceTests.swift
git commit -m "feat: FontSmoothingService with global/per-app smoothing and app discovery"
```

---

## Task 8: App Shell & Navigation

**Files:**
- Modify: `Sources/CrispySquares/CrispySquaresApp.swift`
- Create: `Sources/CrispySquares/Views/SettingsWindow.swift`
- Create: `Sources/CrispySquares/Views/SidebarView.swift`
- Create: `Sources/CrispySquares/Views/DisplayPicker.swift`
- Create: `Sources/CrispySquares/Views/TextPreviewView.swift`

- [ ] **Step 1: Create sidebar navigation enum and view**

Create `Sources/CrispySquares/Views/SidebarView.swift`:

```swift
import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case fontSmoothing = "Font Smoothing"
    case gammaColor = "Gamma & Color"
    case iccProfiles = "ICC Profiles"
    case hidpiScaling = "HiDPI Scaling"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .fontSmoothing: return "textformat"
        case .gammaColor: return "slider.horizontal.3"
        case .iccProfiles: return "doc.badge.gearshape"
        case .hidpiScaling: return "rectangle.on.rectangle"
        }
    }

    var isAvailable: Bool {
        self != .hidpiScaling
    }
}

struct SidebarView: View {
    @Binding var selection: SidebarItem

    var body: some View {
        List(SidebarItem.allCases, selection: $selection) { item in
            Label(item.rawValue, systemImage: item.icon)
                .foregroundStyle(item.isAvailable ? .primary : .tertiary)
                .tag(item)
        }
        .listStyle(.sidebar)
    }
}
```

- [ ] **Step 2: Create display picker**

Create `Sources/CrispySquares/Views/DisplayPicker.swift`:

```swift
import SwiftUI
import CoreGraphics

struct DisplayPicker: View {
    @EnvironmentObject var displayManager: DisplayManager

    var body: some View {
        if displayManager.displays.count > 1 {
            Picker("Display", selection: Binding(
                get: { displayManager.selectedDisplayID ?? 0 },
                set: { displayManager.selectedDisplayID = $0 }
            )) {
                ForEach(displayManager.displays) { display in
                    Text("\(display.name) (\(display.width)x\(display.height))")
                        .tag(display.id)
                }
            }
            .pickerStyle(.menu)
        }
    }
}
```

- [ ] **Step 3: Create text preview view**

Create `Sources/CrispySquares/Views/TextPreviewView.swift`:

```swift
import SwiftUI

struct TextPreviewView: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)

            Group {
                Text("The quick brown fox jumps over the lazy dog.")
                    .font(.system(size: 10))
                Text("The quick brown fox jumps over the lazy dog.")
                    .font(.system(size: 12))
                Text("The quick brown fox jumps over the lazy dog.")
                    .font(.system(size: 14))
                Text("The quick brown fox jumps over the lazy dog.")
                    .font(.system(size: 18))
            }

            Divider()

            Text("func main() { print(\"Hello, world!\") }")
                .font(.system(size: 13, design: .monospaced))

            Text("Settings · Preferences · System · Display")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.separator, lineWidth: 1)
        )
    }
}
```

- [ ] **Step 4: Create settings window**

Create `Sources/CrispySquares/Views/SettingsWindow.swift`:

```swift
import SwiftUI

struct SettingsWindow: View {
    @State private var selectedItem: SidebarItem = .fontSmoothing

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedItem)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            VStack {
                DisplayPicker()
                    .padding(.horizontal)
                    .padding(.top, 8)

                detailView
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("CrispySquares")
        .frame(minWidth: 700, minHeight: 500)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedItem {
        case .fontSmoothing:
            Text("Font Smoothing — coming in Task 9")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .gammaColor:
            Text("Gamma & Color — coming in Task 11")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .iccProfiles:
            Text("ICC Profiles — coming in Task 12")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .hidpiScaling:
            VStack(spacing: 12) {
                Image(systemName: "rectangle.on.rectangle")
                    .font(.system(size: 48))
                    .foregroundStyle(.tertiary)
                Text("HiDPI Scaling")
                    .font(.title2)
                Text("Coming Soon")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
```

- [ ] **Step 5: Update app entry point**

Replace the contents of `Sources/CrispySquares/CrispySquaresApp.swift`:

```swift
import SwiftUI

@main
struct CrispySquaresApp: App {
    @StateObject private var displayManager = DisplayManager()
    @StateObject private var gammaEngine = GammaEngine()
    @StateObject private var fontSmoothingService = FontSmoothingService()

    var body: some Scene {
        MenuBarExtra("CrispySquares", systemImage: "display") {
            Button("Open Settings...") {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: { $0.title == "CrispySquares" }) {
                    window.makeKeyAndOrderFront(nil)
                }
            }
            .keyboardShortcut(",")

            Divider()

            Button("Reset All Displays") {
                gammaEngine.resetAllDisplays()
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }

        Window("CrispySquares", id: "settings") {
            SettingsWindow()
                .environmentObject(displayManager)
                .environmentObject(gammaEngine)
                .environmentObject(fontSmoothingService)
        }
        .defaultSize(width: 800, height: 550)
    }
}
```

- [ ] **Step 6: Build and verify**

```bash
xcodegen generate && xcodebuild build -project CrispySquares.xcodeproj -scheme CrispySquares -destination 'platform=macOS' -derivedDataPath .build 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 7: Commit**

```bash
git add Sources/CrispySquares/
git commit -m "feat: app shell with MenuBarExtra, settings window, sidebar navigation"
```

---

## Task 9: Font Smoothing Module UI

**Files:**
- Create: `Sources/CrispySquares/Views/FontSmoothingView.swift`
- Create: `Sources/CrispySquares/Views/AppOverrideRow.swift`
- Modify: `Sources/CrispySquares/Views/SettingsWindow.swift`

- [ ] **Step 1: Create AppOverrideRow**

Create `Sources/CrispySquares/Views/AppOverrideRow.swift`:

```swift
import SwiftUI

struct AppOverrideRow: View {
    let app: AppInfo
    @State var smoothingValue: Int
    let onChange: (Int) -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 24, height: 24)
            }

            Text(app.name)
                .frame(maxWidth: .infinity, alignment: .leading)

            Picker("", selection: $smoothingValue) {
                Text("Off").tag(0)
                Text("Light").tag(1)
                Text("Medium").tag(2)
                Text("Strong").tag(3)
            }
            .pickerStyle(.segmented)
            .frame(width: 220)
            .onChange(of: smoothingValue) { _, newValue in
                onChange(newValue)
            }

            Button(role: .destructive) {
                onRemove()
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
```

- [ ] **Step 2: Create FontSmoothingView**

Create `Sources/CrispySquares/Views/FontSmoothingView.swift`:

```swift
import SwiftUI

struct FontSmoothingView: View {
    @EnvironmentObject var fontSmoothingService: FontSmoothingService
    @State private var globalSmoothing: Int = 2
    @State private var overrides: [(app: AppInfo, value: Int)] = []
    @State private var showingAppPicker = false
    @State private var availableApps: [AppInfo] = []

    var body: some View {
        HSplitView {
            // Controls
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Caveat banner
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Font smoothing has limited effect on macOS 14+. For the most impactful improvement, use the Gamma & Color module.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(.blue.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Global setting
                    GroupBox("Global Font Smoothing") {
                        VStack(alignment: .leading, spacing: 8) {
                            Picker("Level", selection: $globalSmoothing) {
                                Text("Off").tag(0)
                                Text("Light").tag(1)
                                Text("Medium").tag(2)
                                Text("Strong").tag(3)
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: globalSmoothing) { _, newValue in
                                fontSmoothingService.globalFontSmoothing = newValue
                            }

                            Text("Requires logout to take full effect system-wide.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(8)
                    }

                    // Per-app overrides
                    GroupBox("Per-App Overrides") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(overrides.enumerated()), id: \.element.app.id) { index, override_ in
                                AppOverrideRow(
                                    app: override_.app,
                                    smoothingValue: override_.value,
                                    onChange: { newValue in
                                        overrides[index].value = newValue
                                        fontSmoothingService.setFontSmoothing(newValue, for: override_.app.bundleIdentifier)
                                    },
                                    onRemove: {
                                        fontSmoothingService.removeFontSmoothing(for: override_.app.bundleIdentifier)
                                        overrides.remove(at: index)
                                    }
                                )
                            }

                            Button {
                                availableApps = fontSmoothingService.installedApps()
                                showingAppPicker = true
                            } label: {
                                Label("Add App Override", systemImage: "plus.circle")
                            }
                            .padding(.top, 4)

                            Text("App must be relaunched for override to take effect.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(8)
                    }
                }
                .padding()
            }
            .frame(minWidth: 350)

            // Preview
            TextPreviewView(title: "Preview")
                .padding()
                .frame(minWidth: 250)
        }
        .onAppear {
            globalSmoothing = fontSmoothingService.globalFontSmoothing ?? 2
        }
        .sheet(isPresented: $showingAppPicker) {
            AppPickerSheet(
                apps: availableApps,
                existingOverrides: Set(overrides.map(\.app.bundleIdentifier))
            ) { app in
                overrides.append((app: app, value: globalSmoothing))
                fontSmoothingService.setFontSmoothing(globalSmoothing, for: app.bundleIdentifier)
            }
        }
    }
}

struct AppPickerSheet: View {
    let apps: [AppInfo]
    let existingOverrides: Set<String>
    let onSelect: (AppInfo) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var filteredApps: [AppInfo] {
        let available = apps.filter { !existingOverrides.contains($0.bundleIdentifier) }
        if searchText.isEmpty { return available }
        return available.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search apps...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding()

            List(filteredApps) { app in
                Button {
                    onSelect(app)
                    dismiss()
                } label: {
                    HStack {
                        if let icon = app.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 20, height: 20)
                        }
                        Text(app.name)
                        Spacer()
                        Text(app.bundleIdentifier)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 450, height: 400)
    }
}
```

- [ ] **Step 3: Wire FontSmoothingView into SettingsWindow**

In `Sources/CrispySquares/Views/SettingsWindow.swift`, replace the `.fontSmoothing` case in `detailView`:

```swift
        case .fontSmoothing:
            FontSmoothingView()
```

- [ ] **Step 4: Build and verify**

```bash
xcodegen generate && xcodebuild build -project CrispySquares.xcodeproj -scheme CrispySquares -destination 'platform=macOS' -derivedDataPath .build 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 5: Commit**

```bash
git add Sources/CrispySquares/Views/
git commit -m "feat: Font Smoothing module with global toggle, per-app overrides, and preview"
```

---

## Task 10: Curve Editor NSView

**Files:**
- Create: `Sources/CrispySquares/Views/CurveEditorNSView.swift`
- Create: `Sources/CrispySquares/Views/CurveEditorView.swift`

- [ ] **Step 1: Implement CurveEditorNSView**

Create `Sources/CrispySquares/Views/CurveEditorNSView.swift`:

```swift
import AppKit
import CoreGraphics

protocol CurveEditorDelegate: AnyObject {
    func curveEditorDidUpdatePoints(_ editor: CurveEditorNSView, points: [GammaCurve.ControlPoint])
}

final class CurveEditorNSView: NSView {
    weak var delegate: CurveEditorDelegate?

    var controlPoints: [GammaCurve.ControlPoint] = [
        GammaCurve.ControlPoint(x: 0.0, y: 0.0),
        GammaCurve.ControlPoint(x: 1.0, y: 1.0),
    ] {
        didSet { needsDisplay = true }
    }

    var showPerChannel = false
    var activeChannel: Channel = .all

    enum Channel {
        case all, red, green, blue
    }

    private var draggedPointIndex: Int?
    private let pointRadius: CGFloat = 6.0
    private let hitRadius: CGFloat = 12.0

    // MARK: - Drawing

    override var isFlipped: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let inset: CGFloat = 20
        let plotRect = bounds.insetBy(dx: inset, dy: inset)

        drawBackground(context: context, rect: plotRect)
        drawGrid(context: context, rect: plotRect)
        drawReferenceLine(context: context, rect: plotRect)
        drawCurve(context: context, rect: plotRect)
        drawControlPoints(context: context, rect: plotRect)
    }

    private func drawBackground(context: CGContext, rect: CGRect) {
        context.setFillColor(NSColor(white: 0.1, alpha: 1).cgColor)
        context.fill(rect)
    }

    private func drawGrid(context: CGContext, rect: CGRect) {
        context.setStrokeColor(NSColor(white: 0.2, alpha: 1).cgColor)
        context.setLineWidth(0.5)

        for i in 0...4 {
            let frac = CGFloat(i) / 4.0
            let x = rect.minX + frac * rect.width
            let y = rect.minY + frac * rect.height

            context.move(to: CGPoint(x: x, y: rect.minY))
            context.addLine(to: CGPoint(x: x, y: rect.maxY))
            context.strokePath()

            context.move(to: CGPoint(x: rect.minX, y: y))
            context.addLine(to: CGPoint(x: rect.maxX, y: y))
            context.strokePath()
        }
    }

    private func drawReferenceLine(context: CGContext, rect: CGRect) {
        context.setStrokeColor(NSColor(white: 0.35, alpha: 1).cgColor)
        context.setLineWidth(1)
        context.setLineDash(phase: 0, lengths: [4, 4])
        context.move(to: CGPoint(x: rect.minX, y: rect.minY))
        context.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        context.strokePath()
        context.setLineDash(phase: 0, lengths: [])
    }

    private func drawCurve(context: CGContext, rect: CGRect) {
        let curve = GammaCurve.controlPoints(controlPoints)
        let steps = 200

        context.setStrokeColor(NSColor.white.cgColor)
        context.setLineWidth(2)

        context.beginPath()
        for i in 0...steps {
            let x = Float(i) / Float(steps)
            let y = curve.evaluate(at: x)
            let px = rect.minX + CGFloat(x) * rect.width
            let py = rect.minY + CGFloat(y) * rect.height

            if i == 0 {
                context.move(to: CGPoint(x: px, y: py))
            } else {
                context.addLine(to: CGPoint(x: px, y: py))
            }
        }
        context.strokePath()
    }

    private func drawControlPoints(context: CGContext, rect: CGRect) {
        for (index, point) in controlPoints.enumerated() {
            let center = pointToView(point, in: rect)
            let isEndpoint = index == 0 || index == controlPoints.count - 1
            let isDragging = draggedPointIndex == index

            // Outer circle
            context.setFillColor(
                isDragging ? NSColor.systemIndigo.cgColor : NSColor.white.cgColor
            )
            context.fillEllipse(in: CGRect(
                x: center.x - pointRadius,
                y: center.y - pointRadius,
                width: pointRadius * 2,
                height: pointRadius * 2
            ))

            // Border
            context.setStrokeColor(
                isEndpoint ? NSColor.systemGray.cgColor : NSColor.systemIndigo.cgColor
            )
            context.setLineWidth(2)
            context.strokeEllipse(in: CGRect(
                x: center.x - pointRadius,
                y: center.y - pointRadius,
                width: pointRadius * 2,
                height: pointRadius * 2
            ))
        }
    }

    // MARK: - Coordinate Conversion

    private var plotRect: CGRect {
        bounds.insetBy(dx: 20, dy: 20)
    }

    private func pointToView(_ point: GammaCurve.ControlPoint, in rect: CGRect) -> CGPoint {
        CGPoint(
            x: rect.minX + CGFloat(point.x) * rect.width,
            y: rect.minY + CGFloat(point.y) * rect.height
        )
    }

    private func viewToPoint(_ viewPoint: CGPoint, in rect: CGRect) -> GammaCurve.ControlPoint {
        let x = Float((viewPoint.x - rect.minX) / rect.width)
        let y = Float((viewPoint.y - rect.minY) / rect.height)
        return GammaCurve.ControlPoint(
            x: min(max(x, 0), 1),
            y: min(max(y, 0), 1)
        )
    }

    // MARK: - Mouse Interaction

    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        let rect = plotRect

        // Find closest point within hit radius
        for (index, point) in controlPoints.enumerated() {
            let center = pointToView(point, in: rect)
            let distance = hypot(location.x - center.x, location.y - center.y)
            if distance <= hitRadius {
                // Don't allow dragging endpoints horizontally
                draggedPointIndex = index
                needsDisplay = true
                return
            }
        }

        // Double-click adds a new point
        if event.clickCount == 2 {
            let newPoint = viewToPoint(location, in: rect)
            if newPoint.x > 0.01 && newPoint.x < 0.99 {
                controlPoints.append(newPoint)
                controlPoints.sort { $0.x < $1.x }
                draggedPointIndex = controlPoints.firstIndex(where: { $0.x == newPoint.x && $0.y == newPoint.y })
                delegate?.curveEditorDidUpdatePoints(self, points: controlPoints)
                needsDisplay = true
            }
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard let index = draggedPointIndex else { return }
        let location = convert(event.locationInWindow, from: nil)
        let rect = plotRect
        var newPoint = viewToPoint(location, in: rect)

        // Endpoints: lock x position
        if index == 0 {
            newPoint = GammaCurve.ControlPoint(x: 0.0, y: newPoint.y)
        } else if index == controlPoints.count - 1 {
            newPoint = GammaCurve.ControlPoint(x: 1.0, y: newPoint.y)
        } else {
            // Interior points: constrain x between neighbors
            let minX = controlPoints[index - 1].x + 0.01
            let maxX = controlPoints[index + 1].x - 0.01
            newPoint = GammaCurve.ControlPoint(
                x: min(max(newPoint.x, minX), maxX),
                y: newPoint.y
            )
        }

        controlPoints[index] = newPoint
        delegate?.curveEditorDidUpdatePoints(self, points: controlPoints)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        draggedPointIndex = nil
        needsDisplay = true
    }

    // Right-click deletes interior points
    override func rightMouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        let rect = plotRect

        for (index, point) in controlPoints.enumerated() {
            let center = pointToView(point, in: rect)
            let distance = hypot(location.x - center.x, location.y - center.y)
            if distance <= hitRadius && index != 0 && index != controlPoints.count - 1 {
                controlPoints.remove(at: index)
                delegate?.curveEditorDidUpdatePoints(self, points: controlPoints)
                needsDisplay = true
                return
            }
        }
    }
}
```

- [ ] **Step 2: Create NSViewRepresentable wrapper**

Create `Sources/CrispySquares/Views/CurveEditorView.swift`:

```swift
import SwiftUI

struct CurveEditorView: NSViewRepresentable {
    @Binding var controlPoints: [GammaCurve.ControlPoint]

    func makeNSView(context: Context) -> CurveEditorNSView {
        let view = CurveEditorNSView()
        view.delegate = context.coordinator
        view.controlPoints = controlPoints
        return view
    }

    func updateNSView(_ nsView: CurveEditorNSView, context: Context) {
        nsView.controlPoints = controlPoints
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, CurveEditorDelegate {
        let parent: CurveEditorView

        init(_ parent: CurveEditorView) {
            self.parent = parent
        }

        func curveEditorDidUpdatePoints(_ editor: CurveEditorNSView, points: [GammaCurve.ControlPoint]) {
            parent.controlPoints = points
        }
    }
}
```

- [ ] **Step 3: Build and verify**

```bash
xcodegen generate && xcodebuild build -project CrispySquares.xcodeproj -scheme CrispySquares -destination 'platform=macOS' -derivedDataPath .build 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add Sources/CrispySquares/Views/CurveEditorNSView.swift Sources/CrispySquares/Views/CurveEditorView.swift
git commit -m "feat: interactive curve editor NSView with drag, add, delete control points"
```

---

## Task 11: Gamma & Color Module UI

**Files:**
- Create: `Sources/CrispySquares/Views/GammaControlsView.swift`
- Create: `Sources/CrispySquares/Views/GammaColorView.swift`
- Modify: `Sources/CrispySquares/Views/SettingsWindow.swift`

- [ ] **Step 1: Create GammaControlsView**

Create `Sources/CrispySquares/Views/GammaControlsView.swift`:

```swift
import SwiftUI

struct GammaControlsView: View {
    @Binding var gamma: Float
    @Binding var contrastBoost: Float
    @Binding var blackPoint: Float
    @Binding var whitePoint: Float
    @Binding var selectedPreset: Preset?
    let customPresets: [Preset]
    let onSavePreset: (String) -> Void

    @State private var showingSavePreset = false
    @State private var newPresetName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Gamma
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Gamma").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f", gamma))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Slider(value: $gamma, in: 0.5...4.0, step: 0.1)
                Text("Default: 2.2 · Lower = bolder text")
                    .font(.caption2).foregroundStyle(.tertiary)
            }

            // Contrast Boost
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Contrast Boost").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.0f%%", contrastBoost * 100))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Slider(value: $contrastBoost, in: 0...0.5, step: 0.05)
            }

            // Black Point
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Black Point").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.2f", blackPoint))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Slider(value: $blackPoint, in: 0...0.2, step: 0.01)
            }

            // White Point
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("White Point").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.2f", whitePoint))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Slider(value: $whitePoint, in: 0.8...1.0, step: 0.01)
            }

            Divider()

            // Presets
            VStack(alignment: .leading, spacing: 8) {
                Text("Presets").font(.caption).foregroundStyle(.secondary)

                ForEach(Preset.builtIn + customPresets) { preset in
                    Button {
                        selectedPreset = preset
                        applyPreset(preset)
                    } label: {
                        HStack {
                            Text(preset.name)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if selectedPreset?.name == preset.name {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 2)
                }

                Button {
                    showingSavePreset = true
                } label: {
                    Label("Save Current as Preset", systemImage: "plus")
                }
                .padding(.top, 4)
            }
        }
        .alert("Save Preset", isPresented: $showingSavePreset) {
            TextField("Preset name", text: $newPresetName)
            Button("Save") {
                onSavePreset(newPresetName)
                newPresetName = ""
            }
            Button("Cancel", role: .cancel) { newPresetName = "" }
        }
    }

    private func applyPreset(_ preset: Preset) {
        switch preset.curve.curveType {
        case let .parametric(g, bp, wp, cb):
            gamma = g
            blackPoint = bp
            whitePoint = wp
            contrastBoost = cb
        case .controlPoints:
            break // Control point presets are handled differently
        }
    }
}
```

- [ ] **Step 2: Create GammaColorView**

Create `Sources/CrispySquares/Views/GammaColorView.swift`:

```swift
import SwiftUI

struct GammaColorView: View {
    @EnvironmentObject var gammaEngine: GammaEngine
    @EnvironmentObject var displayManager: DisplayManager

    @State private var gamma: Float = 2.2
    @State private var contrastBoost: Float = 0.0
    @State private var blackPoint: Float = 0.0
    @State private var whitePoint: Float = 1.0
    @State private var controlPoints: [GammaCurve.ControlPoint] = [
        .init(x: 0, y: 0),
        .init(x: 1, y: 1),
    ]
    @State private var selectedPreset: Preset?
    @State private var customPresets: [Preset] = []
    @State private var isPreviewing = false
    @State private var showingKeepDialog = false
    @State private var keepCountdown = 15

    private var currentCurve: GammaCurve {
        .parametric(gamma: gamma, blackPoint: blackPoint, whitePoint: whitePoint, contrastBoost: contrastBoost)
    }

    var body: some View {
        HSplitView {
            // Curve editor + controls
            VStack(spacing: 0) {
                // Curve editor
                CurveEditorView(controlPoints: $controlPoints)
                    .frame(minHeight: 250)
                    .onChange(of: controlPoints) { _, _ in
                        updateLivePreview()
                    }

                // Channel selector (visual only in v1 — per-channel curve editing is a follow-up)
                HStack(spacing: 4) {
                    ForEach(["All", "R", "G", "B"], id: \.self) { channel in
                        Button(channel) {}
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(channel != "All")
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .frame(minWidth: 300)

            // Controls panel
            ScrollView {
                VStack(spacing: 16) {
                    GammaControlsView(
                        gamma: $gamma,
                        contrastBoost: $contrastBoost,
                        blackPoint: $blackPoint,
                        whitePoint: $whitePoint,
                        selectedPreset: $selectedPreset,
                        customPresets: customPresets,
                        onSavePreset: savePreset
                    )
                    .onChange(of: gamma) { _, _ in updateLivePreview() }
                    .onChange(of: contrastBoost) { _, _ in updateLivePreview() }
                    .onChange(of: blackPoint) { _, _ in updateLivePreview() }
                    .onChange(of: whitePoint) { _, _ in updateLivePreview() }

                    Divider()

                    // Action buttons
                    VStack(spacing: 8) {
                        Button("Apply to Display") {
                            applyToDisplay()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        Button("Reset Display") {
                            resetDisplay()
                        }
                        .controlSize(.regular)
                    }
                }
                .padding()
            }
            .frame(minWidth: 220, maxWidth: 280)
        }
        .alert("Keep Display Settings?", isPresented: $showingKeepDialog) {
            Button("Keep") {
                // Settings are already applied
            }
            Button("Revert", role: .cancel) {
                resetDisplay()
            }
        } message: {
            Text("Reverting in \(keepCountdown) seconds if not confirmed...")
        }
    }

    private func updateLivePreview() {
        guard let displayID = displayManager.selectedDisplay?.id else { return }
        gammaEngine.startPreview(curve: currentCurve, on: displayID)
        isPreviewing = true
    }

    private func applyToDisplay() {
        guard let displayID = displayManager.selectedDisplay?.id else { return }
        gammaEngine.applyGammaTable(curve: currentCurve, to: displayID)

        // Start countdown
        keepCountdown = 15
        showingKeepDialog = true

        // Auto-revert timer
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            keepCountdown -= 1
            if keepCountdown <= 0 {
                timer.invalidate()
                if showingKeepDialog {
                    showingKeepDialog = false
                    resetDisplay()
                }
            }
        }
    }

    private func resetDisplay() {
        gammaEngine.resetAllDisplays()
        isPreviewing = false
        gamma = 2.2
        contrastBoost = 0.0
        blackPoint = 0.0
        whitePoint = 1.0
    }

    private func savePreset(_ name: String) {
        let preset = Preset(name: name, curve: currentCurve, isBuiltIn: false)
        customPresets.append(preset)
    }
}
```

- [ ] **Step 3: Wire GammaColorView into SettingsWindow**

In `Sources/CrispySquares/Views/SettingsWindow.swift`, replace the `.gammaColor` case:

```swift
        case .gammaColor:
            GammaColorView()
```

- [ ] **Step 4: Build and verify**

```bash
xcodegen generate && xcodebuild build -project CrispySquares.xcodeproj -scheme CrispySquares -destination 'platform=macOS' -derivedDataPath .build 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 5: Commit**

```bash
git add Sources/CrispySquares/Views/
git commit -m "feat: Gamma & Color module with curve editor, sliders, presets, and live preview"
```

---

## Task 12: ICC Profiles Module UI

**Files:**
- Create: `Sources/CrispySquares/Views/ProfileRow.swift`
- Create: `Sources/CrispySquares/Views/ICCProfilesView.swift`
- Modify: `Sources/CrispySquares/Views/SettingsWindow.swift`

- [ ] **Step 1: Create ProfileRow**

Create `Sources/CrispySquares/Views/ProfileRow.swift`:

```swift
import SwiftUI

struct ProfileInfo: Identifiable {
    let id: String // file name
    let name: String
    let url: URL
    let creationDate: Date?
    var assignedDisplay: String?
}

struct ProfileRow: View {
    let profile: ProfileInfo
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isActive ? .green : .secondary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .fontWeight(isActive ? .semibold : .regular)

                HStack(spacing: 8) {
                    if let display = profile.assignedDisplay {
                        Text(display)
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    if let date = profile.creationDate {
                        Text(date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
```

- [ ] **Step 2: Create ICCProfilesView**

Create `Sources/CrispySquares/Views/ICCProfilesView.swift`:

```swift
import SwiftUI

struct ICCProfilesView: View {
    @EnvironmentObject var gammaEngine: GammaEngine
    @EnvironmentObject var displayManager: DisplayManager
    @State private var profiles: [ProfileInfo] = []
    @State private var selectedProfileID: String?
    @State private var showingCreateSheet = false
    @State private var newProfileName = ""
    @State private var showingImporter = false

    private let profilesDir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/ColorSync/Profiles")

    var body: some View {
        HSplitView {
            // Profile list
            VStack(alignment: .leading, spacing: 0) {
                List(profiles, selection: $selectedProfileID) { profile in
                    ProfileRow(profile: profile, isActive: profile.assignedDisplay != nil)
                        .tag(profile.id)
                }
                .listStyle(.inset)

                // Actions bar
                HStack(spacing: 8) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }

                    Button {
                        showingImporter = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .help("Import ICC Profile")

                    Button {
                        exportSelectedProfile()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .help("Export ICC Profile")
                    .disabled(selectedProfileID == nil)

                    Spacer()

                    Button(role: .destructive) {
                        deleteSelectedProfile()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(selectedProfileID == nil)
                }
                .padding(8)
                .background(.bar)
            }
            .frame(minWidth: 300)

            // Detail panel
            VStack(spacing: 16) {
                if let selectedID = selectedProfileID,
                   let profile = profiles.first(where: { $0.id == selectedID }) {
                    GroupBox("Profile Details") {
                        VStack(alignment: .leading, spacing: 8) {
                            LabeledContent("Name", value: profile.name)
                            LabeledContent("File", value: profile.url.lastPathComponent)
                            if let date = profile.creationDate {
                                LabeledContent("Created") {
                                    Text(date, style: .date)
                                }
                            }
                        }
                        .padding(8)
                    }

                    GroupBox("Assign to Display") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(displayManager.displays) { display in
                                Button {
                                    let _ = gammaEngine.assignProfile(at: profile.url, to: display.id)
                                    refreshProfiles()
                                } label: {
                                    HStack {
                                        Text("\(display.name) (\(display.width)x\(display.height))")
                                        Spacer()
                                        if profile.assignedDisplay == display.name {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.green)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(8)
                    }

                    Button("Restore Display Defaults") {
                        gammaEngine.resetAllDisplays()
                        refreshProfiles()
                    }
                    .controlSize(.large)

                    Spacer()
                } else {
                    Spacer()
                    Text("Select a profile")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .padding()
            .frame(minWidth: 250)
        }
        .onAppear { refreshProfiles() }
        .alert("Create Profile from Current Gamma", isPresented: $showingCreateSheet) {
            TextField("Profile name", text: $newProfileName)
            Button("Create") {
                createProfileFromCurrentGamma()
                newProfileName = ""
            }
            Button("Cancel", role: .cancel) { newProfileName = "" }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.init(filenameExtension: "icc")].compactMap { $0 }
        ) { result in
            if case let .success(url) = result {
                importProfile(from: url)
            }
        }
    }

    private func refreshProfiles() {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: profilesDir,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            profiles = []
            return
        }

        profiles = contents
            .filter { $0.lastPathComponent.hasPrefix("CrispySquares-") && $0.pathExtension == "icc" }
            .compactMap { url -> ProfileInfo? in
                let name = url.deletingPathExtension().lastPathComponent
                    .replacingOccurrences(of: "CrispySquares-", with: "")
                    .replacingOccurrences(of: "-", with: " ")
                let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
                let date = attrs?[.creationDate] as? Date
                return ProfileInfo(id: url.lastPathComponent, name: name, url: url, creationDate: date)
            }
    }

    private func createProfileFromCurrentGamma() {
        guard !newProfileName.isEmpty else { return }
        guard let displayID = displayManager.selectedDisplay?.id,
              let tables = gammaEngine.readCurrentGammaTable(for: displayID) else { return }
        // Build a curve from the current display gamma tables (captures whatever the Gamma module applied)
        let avgTable = zip(zip(tables.red, tables.green), tables.blue).map { (rg, b) in
            (rg.0 + rg.1 + b) / 3.0
        }
        let curve = GammaCurve.controlPoints(
            stride(from: 0, to: avgTable.count, by: avgTable.count / 16).map { i in
                GammaCurve.ControlPoint(x: Float(i) / Float(avgTable.count - 1), y: avgTable[i])
            } + [GammaCurve.ControlPoint(x: 1.0, y: avgTable.last ?? 1.0)]
        )
        _ = try? gammaEngine.saveAsICCProfile(curve: curve, name: newProfileName)
        refreshProfiles()
    }

    private func importProfile(from url: URL) {
        let destName = "CrispySquares-\(url.deletingPathExtension().lastPathComponent).icc"
        let dest = profilesDir.appendingPathComponent(destName)
        try? FileManager.default.copyItem(at: url, to: dest)
        refreshProfiles()
    }

    private func exportSelectedProfile() {
        guard let selectedID = selectedProfileID,
              let profile = profiles.first(where: { $0.id == selectedID }) else { return }

        let panel = NSSavePanel()
        panel.nameFieldStringValue = profile.url.lastPathComponent
        panel.allowedContentTypes = [.init(filenameExtension: "icc")].compactMap { $0 }
        if panel.runModal() == .OK, let dest = panel.url {
            try? FileManager.default.copyItem(at: profile.url, to: dest)
        }
    }

    private func deleteSelectedProfile() {
        guard let selectedID = selectedProfileID,
              let profile = profiles.first(where: { $0.id == selectedID }) else { return }
        try? FileManager.default.removeItem(at: profile.url)
        selectedProfileID = nil
        refreshProfiles()
    }
}
```

- [ ] **Step 3: Wire ICCProfilesView into SettingsWindow**

In `Sources/CrispySquares/Views/SettingsWindow.swift`, replace the `.iccProfiles` case:

```swift
        case .iccProfiles:
            ICCProfilesView()
```

- [ ] **Step 4: Build and verify**

```bash
xcodegen generate && xcodebuild build -project CrispySquares.xcodeproj -scheme CrispySquares -destination 'platform=macOS' -derivedDataPath .build 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 5: Commit**

```bash
git add Sources/CrispySquares/Views/
git commit -m "feat: ICC Profiles module with create, import, export, assign, and delete"
```

---

## Task 13: System Integration

**Files:**
- Modify: `Sources/CrispySquares/CrispySquaresApp.swift`
- Modify: `Sources/CrispySquares/Services/GammaEngine.swift`
- Modify: `Sources/CrispySquares/Services/DisplayManager.swift`

- [ ] **Step 1: Add launch-at-login support to the app**

In `Sources/CrispySquares/CrispySquaresApp.swift`, add login item management. Replace the file contents:

```swift
import SwiftUI
import ServiceManagement

@main
struct CrispySquaresApp: App {
    @StateObject private var displayManager = DisplayManager()
    @StateObject private var gammaEngine = GammaEngine()
    @StateObject private var fontSmoothingService = FontSmoothingService()
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("CrispySquares", systemImage: "display") {
            Button("Open Settings...") {
                openSettings()
            }
            .keyboardShortcut(",")

            Divider()

            Toggle("Launch at Login", isOn: $appState.launchAtLogin)

            Divider()

            Button("Reset All Displays") {
                gammaEngine.resetAllDisplays()
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }

        Window("CrispySquares", id: "settings") {
            SettingsWindow()
                .environmentObject(displayManager)
                .environmentObject(gammaEngine)
                .environmentObject(fontSmoothingService)
                .environmentObject(appState)
        }
        .defaultSize(width: 800, height: 550)
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows {
            if window.title == "CrispySquares" || window.identifier?.rawValue == "settings" {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }
        // If window not found, open it
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}

final class AppState: ObservableObject {
    @Published var launchAtLogin: Bool {
        didSet {
            setLaunchAtLogin(launchAtLogin)
        }
    }

    init() {
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
        }
    }
}
```

- [ ] **Step 2: Add wake/sleep re-application to GammaEngine**

Add to `Sources/CrispySquares/Services/GammaEngine.swift`, after the `@Published var isLivePreviewing` line:

```swift
    private var savedSettings: [CGDirectDisplayID: GammaCurve] = [:]
    private var wakeObserver: Any?

    func saveSetting(curve: GammaCurve, for displayID: CGDirectDisplayID) {
        savedSettings[displayID] = curve
    }

    func reapplySavedSettings() {
        for (displayID, curve) in savedSettings {
            applyGammaTable(curve: curve, to: displayID)
        }
    }

    func startWakeListener() {
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Debounce: wait for display to stabilize after wake
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.reapplySavedSettings()
            }
        }
    }
```

- [ ] **Step 3: Add display reconfiguration handler to DisplayManager**

Add a callback mechanism to `Sources/CrispySquares/Services/DisplayManager.swift`. Add this property and modify `init`:

```swift
    var onDisplayReconfiguration: (() -> Void)?
```

In the `registerForDisplayChanges` callback, after `manager.refreshDisplays()`, add:

```swift
                manager.onDisplayReconfiguration?()
```

- [ ] **Step 4: Wire wake listener and ConfigStore in app startup**

Add `init` to `GammaEngine` in `Sources/CrispySquares/Services/GammaEngine.swift` and add `import AppKit` at the top of the file:

```swift
    init() {
        startWakeListener()
    }
```

In `Sources/CrispySquares/CrispySquaresApp.swift`, add ConfigStore integration. Add a `configStore` property and load/save config on app lifecycle. Add to `CrispySquaresApp`:

```swift
    private let configStore = ConfigStore()

    init() {
        // Load saved config and re-apply gamma settings on launch
        if let config = try? configStore.load() {
            let engine = GammaEngine()
            for (displayKey, settings) in config.displaySettings {
                if let displayID = CGDirectDisplayID(displayKey) {
                    engine.applyGammaTable(curve: settings.gammaCurve, to: displayID)
                    engine.saveSetting(curve: settings.gammaCurve, for: displayID)
                }
            }
        }
    }
```

This ensures saved gamma settings are re-applied when the app launches (including after login).

- [ ] **Step 5: Add global keyboard shortcut for reset**

In `Sources/CrispySquares/CrispySquaresApp.swift`, add a global event monitor in `AppState.init`:

```swift
    init() {
        self.launchAtLogin = SMAppService.mainApp.status == .enabled

        // Global keyboard shortcut: Cmd+Shift+Escape to reset all displays
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 53 { // 53 = Escape
                CGDisplayRestoreColorSyncSettings()
            }
        }
    }
```

Note: This requires Accessibility permissions. The app should request them gracefully. If denied, the shortcut won't work but the menu bar "Reset All" button still will.

- [ ] **Step 6: Build and verify**

```bash
xcodegen generate && xcodebuild build -project CrispySquares.xcodeproj -scheme CrispySquares -destination 'platform=macOS' -derivedDataPath .build 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 7: Run all tests**

```bash
xcodebuild test -project CrispySquares.xcodeproj -scheme CrispySquares -destination 'platform=macOS' -derivedDataPath .build 2>&1 | tail -15
```

Expected: All tests pass.

- [ ] **Step 8: Commit**

```bash
git add Sources/CrispySquares/
git commit -m "feat: system integration — launch at login, wake re-application, global reset shortcut"
```
