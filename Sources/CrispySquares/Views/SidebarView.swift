import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case fontSmoothing = "Font Smoothing"
    case gammaColor = "Gamma & Color"
    case iccProfiles = "ICC Profiles"
    case hidpiScaling = "HiDPI Scaling"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .fontSmoothing: return "textformat"
        case .gammaColor: return "slider.horizontal.3"
        case .iccProfiles: return "doc.badge.gearshape"
        case .hidpiScaling: return "rectangle.on.rectangle"
        }
    }

    var isAvailable: Bool { self != .hidpiScaling }
}

struct SidebarView: View {
    @Binding var selection: SidebarItem

    var body: some View {
        List(SidebarItem.allCases, selection: $selection) { item in
            Label(item.rawValue, systemImage: item.icon)
                .foregroundStyle(item.isAvailable ? .primary : .tertiary)
                .tag(item)
        }
        .listStyle(.sidebar)
    }
}
