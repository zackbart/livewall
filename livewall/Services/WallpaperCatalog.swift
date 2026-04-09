import Foundation
import AppKit
import AVFoundation
import Combine

final class WallpaperCatalog: ObservableObject {
    static let shared = WallpaperCatalog()

    @Published var wallpapers: [Wallpaper] = []
    @Published var localWallpapers: [Wallpaper] = []

    init() {
        loadSeedCatalog()
        loadLocalWallpapers()
    }

    var allWallpapers: [Wallpaper] {
        localWallpapers + wallpapers
    }

    func loadSeedCatalog() {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(CatalogData.self, from: data) else {
            return
        }

        wallpapers = catalog.wallpapers
    }

    func loadLocalWallpapers() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let localDir = support.appendingPathComponent("livewall/imported", isDirectory: true)

        guard let contents = try? FileManager.default.contentsOfDirectory(at: localDir, includingPropertiesForKeys: nil) else {
            return
        }

        var loaded: [Wallpaper] = []
        for fileURL in contents where fileURL.pathExtension == "mp4" || fileURL.pathExtension == "mov" {
            let wallpaper = Wallpaper.local(
                title: fileURL.deletingPathExtension().lastPathComponent,
                fileURL: fileURL
            )
            loaded.append(wallpaper)
        }

        localWallpapers = loaded
    }

    func addLocalWallpaper(fileURL: URL) async -> Wallpaper? {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let destDir = support.appendingPathComponent("livewall/imported", isDirectory: true)
        try? FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)

        let destURL = destDir.appendingPathComponent(fileURL.lastPathComponent)

        do {
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.copyItem(at: fileURL, to: destURL)

            let asset = AVURLAsset(url: destURL)
            let duration = try await asset.load(.duration).seconds
            let tracks = try await asset.loadTracks(withMediaType: .video)
            let resolution: CGSize
            if let firstTrack = tracks.first {
                resolution = try await firstTrack.load(.naturalSize)
            } else {
                resolution = .zero
            }

            let wallpaperRes: WallpaperResolution
            if resolution.width >= 3840 {
                wallpaperRes = .uhd4k
            } else if resolution.width >= 2560 {
                wallpaperRes = .qhd
            } else if resolution.width >= 1920 {
                wallpaperRes = .hd
            } else {
                wallpaperRes = .unknown
            }

            let wallpaper = Wallpaper.local(
                title: fileURL.deletingPathExtension().lastPathComponent,
                fileURL: destURL,
                resolution: wallpaperRes,
                duration: duration
            )

            localWallpapers.append(wallpaper)

            Task {
                _ = await ThumbnailGenerator.shared.generateThumbnail(for: destURL, wallpaperID: wallpaper.id)
            }

            return wallpaper
        } catch {
            print("Failed to import wallpaper: \(error)")
            return nil
        }
    }

    func search(query: String) -> [Wallpaper] {
        guard !query.isEmpty else { return allWallpapers }
        let lowercased = query.lowercased()
        return allWallpapers.filter { wp in
            wp.title.lowercased().contains(lowercased) ||
            wp.tags.contains { $0.lowercased().contains(lowercased) }
        }
    }

    func filter(by tag: String) -> [Wallpaper] {
        guard !tag.isEmpty else { return allWallpapers }
        return allWallpapers.filter { $0.tags.contains(tag) }
    }

    var allTags: [String] {
        Set(allWallpapers.flatMap(\.tags)).sorted()
    }
}

struct CatalogData: Codable {
    let wallpapers: [Wallpaper]
}
