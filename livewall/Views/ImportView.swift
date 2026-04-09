import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @State private var isShowingFilePicker = false
    @State private var isImporting = false
    @Environment(\.dismiss) private var dismiss

    private let catalog = WallpaperCatalog.shared
    private let engine = WallpaperEngine.shared

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.down.on.square")
                    .font(.system(size: 52, weight: .light))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.tint)

                VStack(spacing: 6) {
                    Text("Import a Wallpaper")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Select an MP4 or MOV video file from your Mac.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 340)
                }

                if isImporting {
                    ProgressView("Importing…")
                        .controlSize(.regular)
                } else {
                    Button {
                        isShowingFilePicker = true
                    } label: {
                        Label("Choose Video File", systemImage: "folder")
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(40)
            .frame(maxWidth: 460)
            .glassEffect(.clear, in: .rect(cornerRadius: 20))

            Spacer()
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
