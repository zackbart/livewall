import SwiftUI

struct WelcomeSheet: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            AppAmbientBackground()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(spacing: 24) {
                    Image(systemName: "sparkles.tv.fill")
                        .font(.system(size: 72, weight: .light))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.tint)

                    VStack(spacing: 8) {
                        Text("Welcome to LiveWall")
                            .font(.system(size: 30, weight: .bold, design: .rounded))

                        Text("Browse the gallery, preview on hover, and apply a living wallpaper to any of your displays.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: 10) {
                        welcomePill(title: "Hover previews", systemImage: "play.circle")
                        welcomePill(title: "Multi-display", systemImage: "display.2")
                        welcomePill(title: "Battery-aware", systemImage: "bolt.badge.clock")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        welcomeRow(
                            icon: "bolt.fill",
                            title: "Battery friendly",
                            detail: "Pauses automatically when you unplug or enable Low Power."
                        )
                        welcomeRow(
                            icon: "square.and.arrow.down",
                            title: "Import your own",
                            detail: "Drop any MP4 or MOV into the gallery window."
                        )
                        welcomeRow(
                            icon: "rectangle.on.rectangle",
                            title: "Multi-display",
                            detail: "Set a different wallpaper on each screen."
                        )
                    }
                    .padding(18)
                    .glassEffect(.regular, in: .rect(cornerRadius: 22))
                }
                .padding(.horizontal, 40)
                .padding(.top, 28)
                .padding(.bottom, 24)
                .background {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.72),
                                    Color(nsColor: .windowBackgroundColor).opacity(0.90)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.32), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 12)
                }

                Spacer(minLength: 0)

                Button {
                    onDismiss()
                } label: {
                    Text("Let's Pick a Wallpaper")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.extraLarge)
                .keyboardShortcut(.defaultAction)
                .padding(.horizontal, 40)
                .padding(.bottom, 32)
            }
        }
        .frame(width: 480, height: 540)
    }

    private func welcomePill(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .glassEffect(.regular, in: .capsule)
    }

    private func welcomeRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}
