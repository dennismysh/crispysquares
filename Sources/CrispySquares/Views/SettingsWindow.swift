import SwiftUI

struct SettingsWindow: View {
    @State private var selectedItem: SidebarItem = .fontSmoothing

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedItem)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            VStack {
                DisplayPicker()
                    .padding(.horizontal)
                    .padding(.top, 8)
                detailView
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("CrispySquares")
        .frame(minWidth: 700, minHeight: 500)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedItem {
        case .fontSmoothing:
            FontSmoothingView()
        case .gammaColor:
            GammaColorView()
        case .iccProfiles:
            Text("ICC Profiles — coming in Task 12")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .hidpiScaling:
            VStack(spacing: 12) {
                Image(systemName: "rectangle.on.rectangle").font(.system(size: 48)).foregroundStyle(.tertiary)
                Text("HiDPI Scaling").font(.title2)
                Text("Coming Soon").foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
