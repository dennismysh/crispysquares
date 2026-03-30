import SwiftUI

struct GammaControlsView: View {
    @Binding var gamma: Float
    @Binding var contrastBoost: Float
    @Binding var blackPoint: Float
    @Binding var whitePoint: Float
    @Binding var selectedPreset: Preset?
    let customPresets: [Preset]
    let onSavePreset: (String) -> Void

    @State private var showingSavePreset = false
    @State private var newPresetName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Gamma").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f", gamma)).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }
                Slider(value: $gamma, in: 0.5...4.0, step: 0.1)
                Text("Default: 2.2 \u{00B7} Lower = bolder text").font(.caption2).foregroundStyle(.tertiary)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Contrast Boost").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.0f%%", contrastBoost * 100)).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }
                Slider(value: $contrastBoost, in: 0...0.5, step: 0.05)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Black Point").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.2f", blackPoint)).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }
                Slider(value: $blackPoint, in: 0...0.2, step: 0.01)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("White Point").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.2f", whitePoint)).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }
                Slider(value: $whitePoint, in: 0.8...1.0, step: 0.01)
            }
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Text("Presets").font(.caption).foregroundStyle(.secondary)
                ForEach(Preset.builtIn + customPresets) { preset in
                    Button {
                        selectedPreset = preset
                        applyPreset(preset)
                    } label: {
                        HStack {
                            Text(preset.name).frame(maxWidth: .infinity, alignment: .leading)
                            if selectedPreset?.name == preset.name {
                                Image(systemName: "checkmark").foregroundStyle(.blue)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 2)
                }
                Button {
                    showingSavePreset = true
                } label: {
                    Label("Save Current as Preset", systemImage: "plus")
                }
                .padding(.top, 4)
            }
        }
        .alert("Save Preset", isPresented: $showingSavePreset) {
            TextField("Preset name", text: $newPresetName)
            Button("Save") {
                onSavePreset(newPresetName)
                newPresetName = ""
            }
            Button("Cancel", role: .cancel) { newPresetName = "" }
        }
    }

    private func applyPreset(_ preset: Preset) {
        switch preset.curve.curveType {
        case let .parametric(g, bp, wp, cb):
            gamma = g
            blackPoint = bp
            whitePoint = wp
            contrastBoost = cb
        case .controlPoints:
            break
        }
    }
}
