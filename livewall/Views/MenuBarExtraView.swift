import SwiftUI

struct MenuBarExtraView: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject private var engine = WallpaperEngine.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("LiveWall")
                        .font(.headline)
                    Text(engine.isPaused ? "Playback paused" : "\(engine.activeWallpapers.count) active wallpaper\(engine.activeWallpapers.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: engine.isPaused ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(
                        engine.isPaused
                            ? AnyShapeStyle(.secondary)
                            : AnyShapeStyle(.tint)
                    )
                    .padding(10)
                    .glassEffect(.regular, in: .capsule)
            }

            Button(engine.isPaused ? "Resume Wallpapers" : "Pause Wallpapers") {
                if engine.isPaused {
                    engine.resumeAll()
                } else {
                    engine.pauseAll()
                }
            }
            .buttonStyle(.glassProminent)
            .controlSize(.regular)
            .keyboardShortcut("p", modifiers: [.command, .shift])

            if !engine.activeWallpapers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Active Wallpapers")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    VStack(spacing: 8) {
                        ForEach(Array(engine.activeWallpapers.values), id: \.id) { wp in
                            HStack(spacing: 10) {
                                Image(systemName: "display")
                                    .foregroundStyle(.tint)
                                    .frame(width: 18)

                                Text(wp.title)
                                    .font(.callout)
                                    .lineLimit(1)

                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .glassEffect(.regular, in: .rect(cornerRadius: 14))
                        }
                    }
                }
            }

            VStack(spacing: 8) {
                menuAction(title: "Open LiveWall", systemImage: "sparkles.tv.fill") {
                    openWindow(id: "main")
                }
                .keyboardShortcut("o", modifiers: .command)

                menuAction(title: "Import Wallpaper…", systemImage: "square.and.arrow.down") {
                    openWindow(id: "import")
                }

                menuAction(title: "Settings…", systemImage: "gearshape") {
                    openWindow(id: "settings")
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            .padding(6)
            .glassEffect(.regular, in: .rect(cornerRadius: 18))

            Button("Quit LiveWall") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 320)
    }

    private func menuAction(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .foregroundStyle(.tint)
                    .frame(width: 18)
                Text(title)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}
