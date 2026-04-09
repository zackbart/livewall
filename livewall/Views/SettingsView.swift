import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared

    private let engine = WallpaperEngine.shared
    private let displayManager = DisplayManager()

    var body: some View {
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
        .frame(minWidth: 480, minHeight: 340)
    }

    private var generalTab: some View {
        Form {
            Section("Performance") {
                Toggle("Pause on battery or low power", isOn: $settings.pauseOnBattery)
                    .help("Automatically pause wallpapers when running on battery power or in Low Power Mode.")

                Toggle("Low power mode", isOn: $settings.lowPowerMode)
                    .help("Reduce CPU usage by pausing wallpaper playback. Enable when running intensive tasks.")
            }

            Section("System") {
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
                    .help("Automatically start LiveWall when you log in.")
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }

    private var displaysTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Connected Displays")
                        .font(.headline)
                    Spacer()
                    Button {
                        displayManager.refreshDisplays()
                        engine.refreshDisplays()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.glass)
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
                }
            }
            .padding(20)
        }
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
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 10))
    }

    private var aboutTab: some View {
        VStack(spacing: 14) {
            Spacer()

            Image(systemName: "sparkles.tv.fill")
                .font(.system(size: 54))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)

            Text("LiveWall")
                .font(.title)
                .fontWeight(.semibold)

            Text("Version 1.0")
                .font(.callout)
                .foregroundStyle(.secondary)

            Text("A lightweight live wallpaper app for macOS.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            Text("Requires macOS 26 or later")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
