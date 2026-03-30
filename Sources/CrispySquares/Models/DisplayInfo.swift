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
            let model = CGDisplayModelNumber(displayID)
            let vendor = CGDisplayVendorNumber(displayID)
            name = "Display \(vendor)-\(model)"
        }
        return DisplayInfo(id: displayID, name: name, width: width, height: height, isBuiltIn: isBuiltIn)
    }
}
