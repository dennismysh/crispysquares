import Foundation
import CoreGraphics
import AppKit

final class GammaEngine: ObservableObject {
    @Published var isLivePreviewing = false

    private var savedSettings: [CGDirectDisplayID: GammaCurve] = [:]
    private var wakeObserver: Any?
    private var previewTimer: Timer?
    private var savedCurveBeforePreview: GammaCurve?

    init() {
        startWakeListener()
    }

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

    // MARK: - Saved Settings & Wake

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
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.reapplySavedSettings()
            }
        }
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
        // ColorSync profile assignment — may need framework linking adjustments
        // For now, return false as a stub; the profile is saved to disk and
        // macOS will pick it up from ~/Library/ColorSync/Profiles/
        return false
    }

    // MARK: - ICC Binary Construction

    private func buildICCProfile(redTable: [Float], greenTable: [Float], blueTable: [Float], description: String) -> Data {
        var data = Data()
        var header = Data(count: 128)
        header.replaceSubrange(4..<8, with: "appl".data(using: .ascii)!)
        header[8] = 0x02; header[9] = 0x10
        header.replaceSubrange(12..<16, with: "mntr".data(using: .ascii)!)
        header.replaceSubrange(16..<20, with: "RGB ".data(using: .ascii)!)
        header.replaceSubrange(20..<24, with: "XYZ ".data(using: .ascii)!)
        let now = Date()
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
        writeUInt16(&header, offset: 24, value: UInt16(components.year!))
        writeUInt16(&header, offset: 26, value: UInt16(components.month!))
        writeUInt16(&header, offset: 28, value: UInt16(components.day!))
        writeUInt16(&header, offset: 30, value: UInt16(components.hour!))
        writeUInt16(&header, offset: 32, value: UInt16(components.minute!))
        writeUInt16(&header, offset: 34, value: UInt16(components.second!))
        header.replaceSubrange(36..<40, with: "acsp".data(using: .ascii)!)
        header.replaceSubrange(40..<44, with: "APPL".data(using: .ascii)!)
        writeS15Fixed16(&header, offset: 68, value: 0.9642)
        writeS15Fixed16(&header, offset: 72, value: 1.0000)
        writeS15Fixed16(&header, offset: 76, value: 0.8249)
        data.append(header)

        let tagCount: UInt32 = 9
        var tagTable = Data()
        writeUInt32(&tagTable, value: tagCount)
        var tagOffset: UInt32 = 128 + 4 + tagCount * 12
        var tagData = Data()

        struct TagEntry { let sig: String; let data: Data }

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
            var paddedData = tag.data
            while paddedData.count % 4 != 0 { paddedData.append(0) }
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
        let totalSize = UInt32(data.count)
        var sizeBytes = Data(count: 4)
        writeUInt32(&sizeBytes, offset: 0, value: totalSize)
        data.replaceSubrange(0..<4, with: sizeBytes)
        return data
    }

    private func buildTextDescriptionTag(_ text: String) -> Data {
        var data = Data()
        data.append("desc".data(using: .ascii)!)
        data.append(Data(count: 4))
        let ascii = text.data(using: .ascii) ?? Data()
        var lenBytes = Data(count: 4)
        writeUInt32(&lenBytes, offset: 0, value: UInt32(ascii.count + 1))
        data.append(lenBytes)
        data.append(ascii)
        data.append(0)
        data.append(Data(count: 4))
        data.append(Data(count: 4))
        data.append(Data(count: 3))
        return data
    }

    private func buildXYZTag(x: Float, y: Float, z: Float) -> Data {
        var data = Data()
        data.append("XYZ ".data(using: .ascii)!)
        data.append(Data(count: 4))
        appendS15Fixed16(&data, value: x)
        appendS15Fixed16(&data, value: y)
        appendS15Fixed16(&data, value: z)
        return data
    }

    private func buildCurveTag(_ table: [Float]) -> Data {
        var data = Data()
        data.append("curv".data(using: .ascii)!)
        data.append(Data(count: 4))
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
