import Foundation
import Combine

enum DownloadState: Equatable {
    case idle
    case downloading(progress: Double)
    case completed(localURL: URL)
    case failed(String)

    static func == (lhs: DownloadState, rhs: DownloadState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.downloading(let lp), .downloading(let rp)): return lp == rp
        case (.completed(let ll), .completed(let rl)): return ll == rl
        case (.failed(let le), .failed(let re)): return le == re
        default: return false
        }
    }

    var isActive: Bool {
        if case .downloading = self { return true }
        return false
    }
}

@MainActor
final class DownloadManager: ObservableObject {
    static let shared = DownloadManager()

    @Published var downloads: [String: DownloadState] = [:]

    private let downloadDirectory: URL

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.downloadDirectory = support.appendingPathComponent("livewall/wallpapers", isDirectory: true)
        try? FileManager.default.createDirectory(at: downloadDirectory, withIntermediateDirectories: true)
    }

    func download(wallpaper: Wallpaper) async {
        guard let url = wallpaper.remoteURL else { return }

        let localURL = downloadDirectory.appendingPathComponent("\(wallpaper.id).mp4")

        if FileManager.default.fileExists(atPath: localURL.path) {
            downloads[wallpaper.id] = .completed(localURL: localURL)
            return
        }

        downloads[wallpaper.id] = .downloading(progress: 0)

        do {
            let (fileURL, _) = try await URLSession.shared.download(from: url)
            try FileManager.default.moveItem(at: fileURL, to: localURL)
            downloads[wallpaper.id] = .completed(localURL: localURL)
        } catch {
            downloads[wallpaper.id] = .failed(error.localizedDescription)
        }
    }

    func localURL(for wallpaperID: String) -> URL? {
        let localURL = downloadDirectory.appendingPathComponent("\(wallpaperID).mp4")
        return FileManager.default.fileExists(atPath: localURL.path) ? localURL : nil
    }

    func isDownloaded(wallpaperID: String) -> Bool {
        localURL(for: wallpaperID) != nil
    }
}
