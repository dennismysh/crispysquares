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
