import SwiftUI

struct TextPreviewView: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title).font(.headline)
            Group {
                Text("The quick brown fox jumps over the lazy dog.").font(.system(size: 10))
                Text("The quick brown fox jumps over the lazy dog.").font(.system(size: 12))
                Text("The quick brown fox jumps over the lazy dog.").font(.system(size: 14))
                Text("The quick brown fox jumps over the lazy dog.").font(.system(size: 18))
            }
            Divider()
            Text("func main() { print(\"Hello, world!\") }")
                .font(.system(size: 13, design: .monospaced))
            Text("Settings · Preferences · System · Display")
                .font(.system(size: 12)).foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.separator, lineWidth: 1))
    }
}
