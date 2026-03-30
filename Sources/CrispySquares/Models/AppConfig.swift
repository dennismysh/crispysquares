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
