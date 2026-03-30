import SwiftUI
import UniformTypeIdentifiers

struct ICCProfilesView: View {
    @EnvironmentObject var gammaEngine: GammaEngine
    @EnvironmentObject var displayManager: DisplayManager
    @State private var profiles: [ProfileInfo] = []
    @State private var selectedProfileID: String?
    @State private var showingCreateSheet = false
    @State private var newProfileName = ""
    @State private var showingImporter = false

    private let profilesDir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/ColorSync/Profiles")

    var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: 0) {
                List(profiles, selection: $selectedProfileID) { profile in
                    ProfileRow(profile: profile, isActive: profile.assignedDisplay != nil)
                        .tag(profile.id)
                }
                .listStyle(.inset)

                HStack(spacing: 8) {
                    Button { showingCreateSheet = true } label: { Image(systemName: "plus") }
                    Button { showingImporter = true } label: { Image(systemName: "square.and.arrow.down") }
                        .help("Import ICC Profile")
                    Button { exportSelectedProfile() } label: { Image(systemName: "square.and.arrow.up") }
                        .help("Export ICC Profile")
                        .disabled(selectedProfileID == nil)
                    Spacer()
                    Button(role: .destructive) { deleteSelectedProfile() } label: { Image(systemName: "trash") }
                        .disabled(selectedProfileID == nil)
                }
                .padding(8)
                .background(.bar)
            }
            .frame(minWidth: 300)

            VStack(spacing: 16) {
                if let selectedID = selectedProfileID,
                   let profile = profiles.first(where: { $0.id == selectedID }) {
                    GroupBox("Profile Details") {
                        VStack(alignment: .leading, spacing: 8) {
                            LabeledContent("Name", value: profile.name)
                            LabeledContent("File", value: profile.url.lastPathComponent)
                            if let date = profile.creationDate {
                                LabeledContent("Created") { Text(date, style: .date) }
                            }
                        }
                        .padding(8)
                    }
                    GroupBox("Assign to Display") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(displayManager.displays) { display in
                                Button {
                                    let _ = gammaEngine.assignProfile(at: profile.url, to: display.id)
                                    refreshProfiles()
                                } label: {
                                    HStack {
                                        Text("\(display.name) (\(display.width)x\(display.height))")
                                        Spacer()
                                        if profile.assignedDisplay == display.name {
                                            Image(systemName: "checkmark").foregroundStyle(.green)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(8)
                    }
                    Button("Restore Display Defaults") {
                        gammaEngine.resetAllDisplays()
                        refreshProfiles()
                    }
                    .controlSize(.large)
                    Spacer()
                } else {
                    Spacer()
                    Text("Select a profile").foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .padding()
            .frame(minWidth: 250)
        }
        .onAppear { refreshProfiles() }
        .alert("Create Profile from Current Gamma", isPresented: $showingCreateSheet) {
            TextField("Profile name", text: $newProfileName)
            Button("Create") {
                createProfile()
                newProfileName = ""
            }
            Button("Cancel", role: .cancel) { newProfileName = "" }
        }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [UTType(filenameExtension: "icc")].compactMap { $0 }) { result in
            if case let .success(url) = result { importProfile(from: url) }
        }
    }

    private func refreshProfiles() {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: profilesDir, includingPropertiesForKeys: [.creationDateKey], options: [.skipsHiddenFiles]
        ) else {
            profiles = []
            return
        }
        profiles = contents
            .filter { $0.lastPathComponent.hasPrefix("CrispySquares-") && $0.pathExtension == "icc" }
            .compactMap { url -> ProfileInfo? in
                let name = url.deletingPathExtension().lastPathComponent
                    .replacingOccurrences(of: "CrispySquares-", with: "")
                    .replacingOccurrences(of: "-", with: " ")
                let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
                let date = attrs?[.creationDate] as? Date
                return ProfileInfo(id: url.lastPathComponent, name: name, url: url, creationDate: date)
            }
    }

    private func createProfile() {
        guard !newProfileName.isEmpty else { return }
        guard let displayID = displayManager.selectedDisplay?.id,
              let tables = gammaEngine.readCurrentGammaTable(for: displayID) else { return }
        let avgTable = zip(zip(tables.red, tables.green), tables.blue).map { (rg, b) in
            (rg.0 + rg.1 + b) / 3.0
        }
        let curve = GammaCurve.controlPoints(
            stride(from: 0, to: avgTable.count, by: avgTable.count / 16).map { i in
                GammaCurve.ControlPoint(x: Float(i) / Float(avgTable.count - 1), y: avgTable[i])
            } + [GammaCurve.ControlPoint(x: 1.0, y: avgTable.last ?? 1.0)]
        )
        _ = try? gammaEngine.saveAsICCProfile(curve: curve, name: newProfileName)
        refreshProfiles()
    }

    private func importProfile(from url: URL) {
        let destName = "CrispySquares-\(url.deletingPathExtension().lastPathComponent).icc"
        let dest = profilesDir.appendingPathComponent(destName)
        try? FileManager.default.copyItem(at: url, to: dest)
        refreshProfiles()
    }

    private func exportSelectedProfile() {
        guard let selectedID = selectedProfileID,
              let profile = profiles.first(where: { $0.id == selectedID }) else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = profile.url.lastPathComponent
        if panel.runModal() == .OK, let dest = panel.url {
            try? FileManager.default.copyItem(at: profile.url, to: dest)
        }
    }

    private func deleteSelectedProfile() {
        guard let selectedID = selectedProfileID,
              let profile = profiles.first(where: { $0.id == selectedID }) else { return }
        try? FileManager.default.removeItem(at: profile.url)
        selectedProfileID = nil
        refreshProfiles()
    }
}
