import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @State private var isShowingFilePicker = false
    @State private var isImporting = false
    @State private var importError: String?
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

                if let error = importError {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
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
                    importError = error.localizedDescription
                }
            }
        }
    }

    private func importFile(_ url: URL) async {
        isImporting = true
        importError = nil

        let accessGranted = url.startAccessingSecurityScopedResource()

        defer {
            if accessGranted {
                url.stopAccessingSecurityScopedResource()
            }
        }

        if let wallpaper = await catalog.addLocalWallpaper(fileURL: url) {
            engine.apply(wallpaper, scope: .allDisplays)
            isImporting = false
            dismiss()
        } else {
            importError = "Failed to import wallpaper. Please try another file."
            isImporting = false
        }
    }
}
