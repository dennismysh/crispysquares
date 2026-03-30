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
    private let fontSmoothingKey = "AppleFontSmoothing"

    var globalFontSmoothing: Int? {
        get {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
            task.arguments = ["read", "-g", fontSmoothingKey]
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
