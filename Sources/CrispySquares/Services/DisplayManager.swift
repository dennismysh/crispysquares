import Foundation
import Combine
import AppKit
import CoreGraphics

final class DisplayManager: ObservableObject {
    @Published var displays: [DisplayInfo] = []
    @Published var selectedDisplayID: CGDirectDisplayID?
    var onDisplayReconfiguration: (() -> Void)?

    private var reconfigurationToken: AnyObject?

    init() {
        refreshDisplays()
        registerForDisplayChanges()
        registerForWakeNotifications()
    }

    deinit {
        if let token = reconfigurationToken {
            NotificationCenter.default.removeObserver(token)
        }
    }

    var selectedDisplay: DisplayInfo? {
        guard let id = selectedDisplayID else { return displays.first }
        return displays.first { $0.id == id }
    }

    func refreshDisplays() {
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: 16)
        var displayCount: UInt32 = 0
        let err = CGGetActiveDisplayList(16, &displayIDs, &displayCount)
        guard err == .success else { return }
        let newDisplays = (0..<Int(displayCount)).map { i in
            DisplayInfo.from(displayID: displayIDs[i])
        }
        DispatchQueue.main.async {
            self.displays = newDisplays
            if let selected = self.selectedDisplayID,
               !newDisplays.contains(where: { $0.id == selected }) {
                self.selectedDisplayID = newDisplays.first?.id
            }
            if self.selectedDisplayID == nil {
                self.selectedDisplayID = newDisplays.first?.id
            }
        }
    }

    private func registerForDisplayChanges() {
        CGDisplayRegisterReconfigurationCallback({ displayID, flags, userInfo in
            guard let manager = userInfo.map({ Unmanaged<DisplayManager>.fromOpaque($0).takeUnretainedValue() }) else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                manager.refreshDisplays()
                manager.onDisplayReconfiguration?()
            }
        }, Unmanaged.passUnretained(self).toOpaque())
    }

    private func registerForWakeNotifications() {
        reconfigurationToken = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.refreshDisplays()
            }
        }
    }
}
