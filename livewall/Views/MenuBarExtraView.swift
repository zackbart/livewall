import SwiftUI

struct MenuBarExtraView: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject private var engine = WallpaperEngine.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(engine.isPaused ? "Resume Wallpapers" : "Pause Wallpapers") {
                if engine.isPaused {
                    engine.resumeAll()
                } else {
                    engine.pauseAll()
                }
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])

            if !engine.activeWallpapers.isEmpty {
                Divider()

                Text("Active Wallpapers")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(Array(engine.activeWallpapers.values), id: \.id) { wp in
                    Label(wp.title, systemImage: "display")
                        .labelStyle(.titleAndIcon)
                        .font(.callout)
                        .foregroundStyle(.primary)
                }
            }

            Divider()

            Button("Open LiveWall") {
                openWindow(id: "main")
            }
            .keyboardShortcut("o", modifiers: .command)

            Button("Import Wallpaper…") {
                openWindow(id: "import")
            }

            Button("Settings…") {
                openWindow(id: "settings")
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Quit LiveWall") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }
}
