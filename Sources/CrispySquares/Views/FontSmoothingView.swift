import SwiftUI

struct FontSmoothingView: View {
    @EnvironmentObject var fontSmoothingService: FontSmoothingService
    @State private var globalSmoothing: Int = 2
    @State private var overrides: [(app: AppInfo, value: Int)] = []
    @State private var showingAppPicker = false
    @State private var availableApps: [AppInfo] = []

    var body: some View {
        HSplitView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Caveat banner
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill").foregroundStyle(.blue)
                        Text("Font smoothing has limited effect on macOS 14+. For the most impactful improvement, use the Gamma & Color module.")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(.blue.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    GroupBox("Global Font Smoothing") {
                        VStack(alignment: .leading, spacing: 8) {
                            Picker("Level", selection: $globalSmoothing) {
                                Text("Off").tag(0)
                                Text("Light").tag(1)
                                Text("Medium").tag(2)
                                Text("Strong").tag(3)
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: globalSmoothing) { newValue in
                                fontSmoothingService.globalFontSmoothing = newValue
                            }
                            Text("Requires logout to take full effect system-wide.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(8)
                    }

                    GroupBox("Per-App Overrides") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(overrides.enumerated()), id: \.element.app.id) { index, override_ in
                                AppOverrideRow(
                                    app: override_.app,
                                    smoothingValue: override_.value,
                                    onChange: { newValue in
                                        overrides[index].value = newValue
                                        fontSmoothingService.setFontSmoothing(newValue, for: override_.app.bundleIdentifier)
                                    },
                                    onRemove: {
                                        fontSmoothingService.removeFontSmoothing(for: override_.app.bundleIdentifier)
                                        overrides.remove(at: index)
                                    }
                                )
                            }
                            Button {
                                availableApps = fontSmoothingService.installedApps()
                                showingAppPicker = true
                            } label: {
                                Label("Add App Override", systemImage: "plus.circle")
                            }
                            .padding(.top, 4)
                            Text("App must be relaunched for override to take effect.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(8)
                    }
                }
                .padding()
            }
            .frame(minWidth: 350)

            TextPreviewView(title: "Preview")
                .padding()
                .frame(minWidth: 250)
        }
        .onAppear {
            globalSmoothing = fontSmoothingService.globalFontSmoothing ?? 2
        }
        .sheet(isPresented: $showingAppPicker) {
            AppPickerSheet(
                apps: availableApps,
                existingOverrides: Set(overrides.map(\.app.bundleIdentifier))
            ) { app in
                overrides.append((app: app, value: globalSmoothing))
                fontSmoothingService.setFontSmoothing(globalSmoothing, for: app.bundleIdentifier)
            }
        }
    }
}

struct AppPickerSheet: View {
    let apps: [AppInfo]
    let existingOverrides: Set<String>
    let onSelect: (AppInfo) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var filteredApps: [AppInfo] {
        let available = apps.filter { !existingOverrides.contains($0.bundleIdentifier) }
        if searchText.isEmpty { return available }
        return available.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search apps...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding()
            List(filteredApps) { app in
                Button {
                    onSelect(app)
                    dismiss()
                } label: {
                    HStack {
                        if let icon = app.icon {
                            Image(nsImage: icon).resizable().frame(width: 20, height: 20)
                        }
                        Text(app.name)
                        Spacer()
                        Text(app.bundleIdentifier).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 450, height: 400)
    }
}
