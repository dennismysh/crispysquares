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
        Preset(name: "Bold Text", curve: .parametric(gamma: 1.8), isBuiltIn: true),
        Preset(name: "High Contrast", curve: .parametric(gamma: 2.2, contrastBoost: 0.3), isBuiltIn: true),
        Preset(name: "Warm Reading", curve: .parametric(gamma: 1.9), isBuiltIn: true),
        Preset(name: "sRGB Standard", curve: .parametric(gamma: 2.2), isBuiltIn: true),
    ]
}
