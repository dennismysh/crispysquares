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
            SettingsMenuContent()
                .environmentObject(gammaEngine)
                .environmentObject(appState)
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
}

struct SettingsMenuContent: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject var gammaEngine: GammaEngine
    @EnvironmentObject var appState: AppState

    var body: some View {
        Button("Open Settings...") {
            openWindow(id: "settings")
            NSApp.activate(ignoringOtherApps: true)
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
