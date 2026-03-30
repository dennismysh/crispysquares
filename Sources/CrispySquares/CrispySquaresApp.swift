import SwiftUI
import ServiceManagement

@main
struct CrispySquaresApp: App {
    @StateObject private var displayManager = DisplayManager()
    @StateObject private var gammaEngine = GammaEngine()
    @StateObject private var fontSmoothingService = FontSmoothingService()
    @StateObject private var appState = AppState()

    // TODO: Wire ConfigStore for persistence (tracked as follow-up)

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

        // Global keyboard shortcut: Cmd+Shift+Escape to reset all displays
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 53 {
                CGDisplayRestoreColorSyncSettings()
            }
        }
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
