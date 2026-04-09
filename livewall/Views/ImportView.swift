import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @State private var isShowingFilePicker = false
    @State private var isImporting = false
    @Environment(\.dismiss) private var dismiss

    private let catalog = WallpaperCatalog.shared
    private let engine = WallpaperEngine.shared

    var body: some View {
        ZStack {
            AppAmbientBackground()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 22) {
                    Image(systemName: "square.and.arrow.down.on.square")
                        .font(.system(size: 56, weight: .light))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.tint)

                    VStack(spacing: 8) {
                        Text("Import a Wallpaper")
                            .font(.system(size: 28, weight: .bold, design: .rounded))

                        Text("Select an MP4 or MOV video file from your Mac and LiveWall will import it into your personal library.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 360)
                    }

                    HStack(spacing: 10) {
                        importPill(title: "MP4 + MOV", systemImage: "film")
                        importPill(title: "Applies to all displays", systemImage: "display.2")
                        importPill(title: "Local-first", systemImage: "folder.fill")
                    }

                    if isImporting {
                        ProgressView("Importing…")
                            .controlSize(.regular)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .glassEffect(.regular, in: .capsule)
                    } else {
                        Button {
                            isShowingFilePicker = true
                        } label: {
                            Label("Choose Video File", systemImage: "folder")
                                .frame(minWidth: 180)
                        }
                        .buttonStyle(.glassProminent)
                        .controlSize(.large)
                        .keyboardShortcut(.defaultAction)
                    }

                    Text("Tip: short seamless loops feel best as wallpapers.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(40)
                .frame(maxWidth: 520)
                .background {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.72),
                                    Color(nsColor: .windowBackgroundColor).opacity(0.92)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.34), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 12)
                }

                Spacer()
            }
        }
        .frame(minWidth: 480, minHeight: 380)
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.mpeg4Movie, .quickTimeMovie, .video],
            allowsMultipleSelection: false
        ) { result in
            Task {
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        await importFile(url)
                    }
                case .failure(let error):
                    AppErrorPresenter.report(
                        title: "Couldn't Open File",
                        message: error.localizedDescription,
                        recoverySuggestion: "Try selecting a different file."
                    )
                }
            }
        }
    }

    private func importPill(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .glassEffect(.regular, in: .capsule)
    }

    private func importFile(_ url: URL) async {
        isImporting = true
        defer { isImporting = false }

        let accessGranted = url.startAccessingSecurityScopedResource()
        defer {
            if accessGranted {
                url.stopAccessingSecurityScopedResource()
            }
        }

        // addLocalWallpaper surfaces errors via the global presenter on failure.
        if let wallpaper = await catalog.addLocalWallpaper(fileURL: url) {
            engine.apply(wallpaper, scope: .allDisplays)
            dismiss()
        }
    }
}
