import SwiftUI

struct WelcomeSheet: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(spacing: 22) {
                Image(systemName: "sparkles.tv.fill")
                    .font(.system(size: 68, weight: .light))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.tint)

                VStack(spacing: 8) {
                    Text("Welcome to LiveWall")
                        .font(.system(size: 28, weight: .semibold))

                    Text("Browse the gallery, preview on hover, and apply a\nliving wallpaper to any of your displays.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
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
                .padding(.top, 4)
            }
            .padding(.horizontal, 40)

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
        .frame(width: 480, height: 540)
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
