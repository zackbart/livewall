import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared

    private let engine = WallpaperEngine.shared
    private let displayManager = DisplayManager()

    var body: some View {
        ZStack {
            AppAmbientBackground()

            TabView {
                generalTab
                    .tabItem {
                        Label("General", systemImage: "gearshape")
                    }

                displaysTab
                    .tabItem {
                        Label("Displays", systemImage: "display.2")
                    }

                aboutTab
                    .tabItem {
                        Label("About", systemImage: "info.circle")
                    }
            }
        }
        .frame(minWidth: 480, minHeight: 340)
    }

    private var generalTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                settingsHero(
                    title: "Playback, without the clutter.",
                    detail: "Keep LiveWall responsive, battery-aware, and quietly present in the background.",
                    systemImage: "dial.low"
                )

                settingsSection(
                    title: "Performance",
                    detail: "Control how aggressively LiveWall yields to power conditions."
                ) {
                    preferenceRow(
                        title: "Pause on battery or low power",
                        detail: "Automatically pause wallpapers when running on battery power or in Low Power Mode.",
                        systemImage: "bolt.slash",
                        isOn: $settings.pauseOnBattery
                    )

                    Divider()

                    preferenceRow(
                        title: "Low power mode",
                        detail: "Reduce CPU usage by pausing wallpaper playback while you focus on heavier tasks.",
                        systemImage: "leaf",
                        isOn: $settings.lowPowerMode
                    )
                }

                settingsSection(
                    title: "System",
                    detail: "Choose whether LiveWall should already be waiting for you after login."
                ) {
                    preferenceRow(
                        title: "Launch at login",
                        detail: "Automatically start LiveWall when you log in.",
                        systemImage: "power",
                        isOn: $settings.launchAtLogin
                    )
                }
            }
            .padding(24)
        }
    }

    private var displaysTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                settingsHero(
                    title: "Displays at a glance.",
                    detail: "See what is connected, what is playing, and refresh the layout when your setup changes.",
                    systemImage: "display.2"
                )

                HStack {
                    settingsStatusPill(
                        title: "\(displayManager.displays.count) connected",
                        systemImage: "display"
                    )
                    settingsStatusPill(
                        title: "\(engine.activeWallpapers.count) active",
                        systemImage: "play.circle.fill"
                    )

                    Spacer()

                    Button {
                        displayManager.refreshDisplays()
                        engine.refreshDisplays()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.regular)
                }

                if displayManager.displays.isEmpty {
                    ContentUnavailableView(
                        "No Displays Detected",
                        systemImage: "display.trianglebadge.exclamationmark",
                        description: Text("Connect a display and tap Refresh.")
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 10) {
                        ForEach(displayManager.displays) { display in
                            displayRow(display)
                        }
                    }
                    .padding(6)
                    .glassEffect(.regular, in: .rect(cornerRadius: 22))
                }
            }
            .padding(24)
        }
    }

    private var aboutTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                settingsHero(
                    title: "LiveWall",
                    detail: "A lightweight live wallpaper app for macOS that keeps the desktop cinematic without turning the rest of the system into noise.",
                    systemImage: "sparkles.tv.fill"
                )

                settingsSection(
                    title: "What it does well",
                    detail: "The product is intentionally focused and desktop-native."
                ) {
                    aboutRow(
                        title: "Multi-display playback",
                        detail: "Run a different live wallpaper on each connected screen.",
                        systemImage: "rectangle.on.rectangle"
                    )

                    Divider()

                    aboutRow(
                        title: "Hover and inline previews",
                        detail: "See motion before applying whenever the video is already on disk.",
                        systemImage: "play.rectangle"
                    )

                    Divider()

                    aboutRow(
                        title: "Power-aware behavior",
                        detail: "Pause automatically on battery or low power when you want it to.",
                        systemImage: "bolt.badge.clock"
                    )
                }

                HStack(spacing: 10) {
                    settingsStatusPill(title: "Version 1.0", systemImage: "app.badge")
                    settingsStatusPill(title: "macOS 26+", systemImage: "desktopcomputer")
                }
            }
            .padding(24)
        }
    }

    private func settingsHero(title: String, detail: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text(detail)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.tint)
                .padding(18)
                .glassEffect(.regular, in: .rect(cornerRadius: 20))
        }
        .padding(22)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.70),
                            Color(nsColor: .windowBackgroundColor).opacity(0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.30), lineWidth: 1)
                }
        }
    }

    private func settingsSection<Content: View>(title: String, detail: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 0) {
                content()
            }
            .padding(6)
            .glassEffect(.regular, in: .rect(cornerRadius: 22))
        }
    }

    private func preferenceRow(title: String, detail: String, systemImage: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .frame(width: 26)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
        }
        .toggleStyle(.switch)
    }

    private func settingsStatusPill(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .glassEffect(.regular, in: .capsule)
    }

    private func displayRow(_ display: DisplayInfo) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "display")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(display.localizedName)
                    .font(.system(size: 13, weight: .medium))
                Text(String(format: "%.0f × %.0f", display.resolution.width, display.resolution.height))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let activeWP = engine.activeWallpapers[display.id] {
                Label(activeWP.title, systemImage: "play.circle.fill")
                    .labelStyle(.titleAndIcon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                Text("No wallpaper")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    private func aboutRow(title: String, detail: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
    }
}
