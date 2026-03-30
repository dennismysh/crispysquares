import SwiftUI
import CoreGraphics

struct DisplayPicker: View {
    @EnvironmentObject var displayManager: DisplayManager

    var body: some View {
        if displayManager.displays.count > 1 {
            Picker("Display", selection: Binding(
                get: { displayManager.selectedDisplayID ?? 0 },
                set: { displayManager.selectedDisplayID = $0 }
            )) {
                ForEach(displayManager.displays) { display in
                    Text("\(display.name) (\(display.width)x\(display.height))")
                        .tag(display.id)
                }
            }
            .pickerStyle(.menu)
        }
    }
}
