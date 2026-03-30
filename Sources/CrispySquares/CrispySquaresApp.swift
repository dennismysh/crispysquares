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
