import SwiftUI

struct WallpaperCardView: View {
    let wallpaper: Wallpaper
    let isActive: Bool
    let onTap: () -> Void

    @State private var isHovering = false
    @State private var showPreview = false
    @State private var hoverTask: Task<Void, Never>?

    /// Only show the hover preview if we already have the video locally —
    /// we never start a remote stream on hover.
    private var previewURL: URL? {
        if let local = wallpaper.localFileURL {
            return local
        }
        if let cached = DownloadManager.shared.localURL(for: wallpaper.id) {
            return cached
        }
        return nil
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                thumbnailArea
                metadataArea
            }
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isHovering ? Color.primary.opacity(0.14) : Color.primary.opacity(0.06),
                        lineWidth: 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .compositingGroup()
            .shadow(color: .black.opacity(isHovering ? 0.14 : 0.06), radius: isHovering ? 6 : 3, x: 0, y: isHovering ? 3 : 1)
            .scaleEffect(isHovering ? 1.015 : 1.0, anchor: .center)
            .animation(.easeOut(duration: 0.18), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
            handleHoverChange(hovering)
        }
        .onDisappear {
            hoverTask?.cancel()
            showPreview = false
            VideoPreviewPool.shared.release(id: wallpaper.id)
        }
    }

    // MARK: - Thumbnail area

    private var thumbnailArea: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                staticThumbnail

                if showPreview, let url = previewURL {
                    VideoPreviewPlayer(
                        wallpaperID: wallpaper.id,
                        url: url,
                        isPlaying: true
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .clipped()
                    .transition(.opacity.animation(.easeInOut(duration: 0.25)))
                }
            }

            if isActive {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Active")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .glassEffect(.regular.tint(.green.opacity(0.35)), in: .capsule)
                .padding(8)
            }
        }
        .frame(height: 140)
    }

    @ViewBuilder
    private var staticThumbnail: some View {
        if let thumbnailURL = wallpaper.thumbnailURL, let url = URL(string: thumbnailURL) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .clipped()
            } placeholder: {
                placeholderView
            }
        } else if let cachedThumb = ThumbnailGenerator.shared.cachedThumbnail(for: wallpaper.id),
                  let nsImage = NSImage(contentsOf: cachedThumb) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .clipped()
        } else {
            placeholderView
        }
    }

    private var placeholderView: some View {
        ZStack {
            Rectangle()
                .fill(Color(nsColor: .quaternaryLabelColor))
            Image(systemName: "film.stack")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
    }

    // MARK: - Metadata area

    private var metadataArea: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(wallpaper.title)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .foregroundStyle(.primary)

            HStack(spacing: 6) {
                if !wallpaper.isLocal {
                    Text(wallpaper.resolution.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                if let duration = wallpaper.duration {
                    Text(String(format: "%.0fs", duration))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                if wallpaper.isLocal {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
                Spacer(minLength: 0)
                if previewURL != nil && !isActive {
                    Image(systemName: "play.circle")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .opacity(isHovering ? 0 : 0.6)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Hover debouncing

    private func handleHoverChange(_ hovering: Bool) {
        hoverTask?.cancel()
        if hovering && previewURL != nil {
            hoverTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 500_000_000) // 500ms debounce
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.25)) {
                    showPreview = true
                }
            }
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                showPreview = false
            }
            VideoPreviewPool.shared.release(id: wallpaper.id)
        }
    }
}
