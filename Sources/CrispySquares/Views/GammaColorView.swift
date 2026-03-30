import SwiftUI

struct GammaColorView: View {
    @EnvironmentObject var gammaEngine: GammaEngine
    @EnvironmentObject var displayManager: DisplayManager

    @State private var gamma: Float = 2.2
    @State private var contrastBoost: Float = 0.0
    @State private var blackPoint: Float = 0.0
    @State private var whitePoint: Float = 1.0
    @State private var controlPoints: [GammaCurve.ControlPoint] = [
        .init(x: 0, y: 0), .init(x: 1, y: 1),
    ]
    @State private var selectedPreset: Preset?
    @State private var customPresets: [Preset] = []
    @State private var isPreviewing = false
    @State private var showingKeepDialog = false
    @State private var keepCountdown = 15

    private var currentCurve: GammaCurve {
        .parametric(gamma: gamma, blackPoint: blackPoint, whitePoint: whitePoint, contrastBoost: contrastBoost)
    }

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                CurveEditorView(controlPoints: $controlPoints)
                    .frame(minHeight: 250)

                // Channel selector (visual only in v1)
                HStack(spacing: 4) {
                    ForEach(["All", "R", "G", "B"], id: \.self) { channel in
                        Button(channel) {}
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(channel != "All")
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .frame(minWidth: 300)

            ScrollView {
                VStack(spacing: 16) {
                    GammaControlsView(
                        gamma: $gamma,
                        contrastBoost: $contrastBoost,
                        blackPoint: $blackPoint,
                        whitePoint: $whitePoint,
                        selectedPreset: $selectedPreset,
                        customPresets: customPresets,
                        onSavePreset: savePreset
                    )

                    Divider()

                    VStack(spacing: 8) {
                        Button("Apply to Display") { applyToDisplay() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        Button("Reset Display") { resetDisplay() }
                            .controlSize(.regular)
                    }
                }
                .padding()
            }
            .frame(minWidth: 220, maxWidth: 280)
        }
        .onChange(of: gamma) { _ in updateLivePreview() }
        .onChange(of: contrastBoost) { _ in updateLivePreview() }
        .onChange(of: blackPoint) { _ in updateLivePreview() }
        .onChange(of: whitePoint) { _ in updateLivePreview() }
        .alert("Keep Display Settings?", isPresented: $showingKeepDialog) {
            Button("Keep") { }
            Button("Revert", role: .cancel) { resetDisplay() }
        } message: {
            Text("Reverting in \(keepCountdown) seconds if not confirmed...")
        }
    }

    private func updateLivePreview() {
        guard let displayID = displayManager.selectedDisplay?.id else { return }
        gammaEngine.startPreview(curve: currentCurve, on: displayID)
        isPreviewing = true
    }

    private func applyToDisplay() {
        guard let displayID = displayManager.selectedDisplay?.id else { return }
        gammaEngine.applyGammaTable(curve: currentCurve, to: displayID)
        keepCountdown = 15
        showingKeepDialog = true
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            keepCountdown -= 1
            if keepCountdown <= 0 {
                timer.invalidate()
                if showingKeepDialog {
                    showingKeepDialog = false
                    resetDisplay()
                }
            }
        }
    }

    private func resetDisplay() {
        gammaEngine.resetAllDisplays()
        isPreviewing = false
        gamma = 2.2
        contrastBoost = 0.0
        blackPoint = 0.0
        whitePoint = 1.0
    }

    private func savePreset(_ name: String) {
        let preset = Preset(name: name, curve: currentCurve, isBuiltIn: false)
        customPresets.append(preset)
    }
}
