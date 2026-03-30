import SwiftUI

struct ProfileInfo: Identifiable {
    let id: String
    let name: String
    let url: URL
    let creationDate: Date?
    var assignedDisplay: String?
}

struct ProfileRow: View {
    let profile: ProfileInfo
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isActive ? .green : .secondary)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name).fontWeight(isActive ? .semibold : .regular)
                HStack(spacing: 8) {
                    if let display = profile.assignedDisplay {
                        Text(display).font(.caption).foregroundStyle(.blue)
                    }
                    if let date = profile.creationDate {
                        Text(date, style: .date).font(.caption).foregroundStyle(.tertiary)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
