import SwiftUI

struct AppOverrideRow: View {
    let app: AppInfo
    @State var smoothingValue: Int
    let onChange: (Int) -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if let icon = app.icon {
                Image(nsImage: icon).resizable().frame(width: 24, height: 24)
            }
            Text(app.name).frame(maxWidth: .infinity, alignment: .leading)
            Picker("", selection: $smoothingValue) {
                Text("Off").tag(0)
                Text("Light").tag(1)
                Text("Medium").tag(2)
                Text("Strong").tag(3)
            }
            .pickerStyle(.segmented)
            .frame(width: 220)
            .onChange(of: smoothingValue) { newValue in onChange(newValue) }
            Button(role: .destructive) { onRemove() } label: {
                Image(systemName: "minus.circle.fill").foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
