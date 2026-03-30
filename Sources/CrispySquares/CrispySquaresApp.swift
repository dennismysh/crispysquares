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
