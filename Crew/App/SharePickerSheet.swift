import SwiftUI

struct SharePickerSheet: View {
    @EnvironmentObject private var session: CrewSession

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Share")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                Spacer()
                Button("Cancel") {
                    session.isSharePickerPresented = false
                }
                .keyboardShortcut(.cancelAction)
            }
            .foregroundStyle(CrewTheme.text)

            if session.isLoadingSources {
                Spacer()
                ProgressView("Looking for windows…")
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                List {
                    Section {
                        ForEach(session.shareSources.filter { $0.kind == .display }) { item in
                            sourceRow(item)
                        }
                    } header: {
                        Text("Displays")
                    }
                    Section {
                        ForEach(session.shareSources.filter { $0.kind == .window }) { item in
                            sourceRow(item)
                        }
                    } header: {
                        Text("Windows")
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.inset)
            }
        }
        .padding(22)
        .frame(width: 520, height: 560)
        .background(CrewTheme.bg2)
    }

    private func sourceRow(_ item: ShareSourceItem) -> some View {
        Button {
            Task { await session.share(item) }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(CrewTheme.accent.opacity(0.14))
                        .frame(width: 40, height: 40)
                    Image(systemName: item.kind == .display ? "display" : "macwindow")
                        .foregroundStyle(CrewTheme.accent2)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(CrewTheme.text)
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundStyle(CrewTheme.dim)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CrewTheme.faint)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
