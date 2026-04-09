import SwiftUI
import AVKit

struct WallpaperDetailView: View {
    let wallpaper: Wallpaper
    var onRequestClose: (() -> Void)? = nil

    @ObservedObject private var engine = WallpaperEngine.shared
    @ObservedObject private var downloadManager = DownloadManager.shared
    @ObservedObject private var catalog = WallpaperCatalog.shared

    private let displayManager = DisplayManager()

    private var isStale: Bool {
        catalog.staleLocalWallpaperIDs.contains(wallpaper.id)
    }

    private var previewURL: URL? {
        if let local = wallpaper.localFileURL {
            return local
        }
        return downloadManager.localURL(for: wallpaper.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                heroPreview

                VStack(alignment: .leading, spacing: 10) {
                    Text(wallpaper.title)
                        .font(.title2)
                        .fontWeight(.semibold)

                    HStack(spacing: 14) {
                        Label(wallpaper.resolution.rawValue, systemImage: "display")
                        if let duration = wallpaper.duration {
                            Label(String(format: "%.0fs", duration), systemImage: "clock")
                        }
                        if wallpaper.isLocal {
                            Label("Local file", systemImage: "folder")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if !wallpaper.tags.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(wallpaper.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2.weight(.medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .glassEffect(.regular, in: .capsule)
                            }
                        }
                        .padding(.top, 2)
                    }
                }

                Divider()

                if isStale {
                    staleNotice
                } else {
                    displayPicker
                }
            }
            .padding(20)
        }
        .frame(minWidth: 440, minHeight: 520)
    }

    // MARK: - Stale notice

    private var staleNotice: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("File is missing")
                        .font(.headline)
                    Text("This wallpaper was moved or deleted from your Mac since you imported it. You can remove the entry from your library.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular.tint(.orange.opacity(0.2)), in: .rect(cornerRadius: 12))

            HStack {
                Spacer()
                Button {
                    catalog.removeLocalWallpaper(wallpaper)
                    onRequestClose?()
                } label: {
                    Label("Remove Missing Entry", systemImage: "trash")
                }
                .buttonStyle(.glassProminent)
                .controlSize(.regular)
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    // MARK: - Hero preview

    @ViewBuilder
    private var heroPreview: some View {
        if let url = previewURL {
            VideoPreviewPlayer(
                wallpaperID: "detail-\(wallpaper.id)",
                url: url,
                isPlaying: true
            )
            .frame(maxWidth: .infinity)
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(alignment: .bottomLeading) {
                Label("Live preview", systemImage: "dot.radiowaves.left.and.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .glassEffect(.regular.tint(.black.opacity(0.45)), in: .capsule)
                    .padding(12)
            }
        } else {
            staticHero
        }
    }

    @ViewBuilder
    private var staticHero: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        ZStack {
            if let thumbnailURL = wallpaper.thumbnailURL, let url = URL(string: thumbnailURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty, .failure:
                        Color(nsColor: .quaternaryLabelColor)
                            .overlay {
                                Image(systemName: "film.stack")
                                    .font(.system(size: 40, weight: .light))
                                    .foregroundStyle(.tertiary)
                            }
                    @unknown default:
                        Color(nsColor: .quaternaryLabelColor)
                    }
                }
            } else {
                Color(nsColor: .quaternaryLabelColor)
                    .overlay {
                        Image(systemName: "film.stack")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(.tertiary)
                    }
            }

            if downloadManager.downloads[wallpaper.id]?.isActive == true {
                Color.black.opacity(0.35)
                ProgressView("Downloading preview…")
                    .controlSize(.regular)
                    .foregroundStyle(.white)
            } else {
                Label("Preview unlocks after Apply", systemImage: "play.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .glassEffect(.regular.tint(.black.opacity(0.5)), in: .capsule)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .clipShape(shape)
    }

    // MARK: - Display picker

    private var displayPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Apply to Display")
                    .font(.headline)

                Spacer()

                Button {
                    applyToAllDisplays()
                } label: {
                    Label("Apply to All", systemImage: "rectangle.on.rectangle")
                }
                .buttonStyle(.glassProminent)
                .controlSize(.regular)
                .keyboardShortcut(.defaultAction)
                .disabled(isAnyDownloadInFlight)
            }

            if displayManager.displays.isEmpty {
                Text("No displays detected.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .glassEffect(.regular, in: .rect(cornerRadius: 10))
            } else {
                VStack(spacing: 8) {
                    ForEach(displayManager.displays) { display in
                        displayRow(display)
                    }
                }
            }
        }
    }

    private var isAnyDownloadInFlight: Bool {
        downloadManager.downloads[wallpaper.id]?.isActive == true
    }

    private func displayRow(_ display: DisplayInfo) -> some View {
        let isActive = engine.activeWallpapers[display.id]?.id == wallpaper.id
        let otherActive = engine.activeWallpapers[display.id]
        let downloadState = downloadManager.downloads[wallpaper.id]

        return HStack(spacing: 12) {
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

            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            } else if let other = otherActive, other.id != wallpaper.id {
                Text(other.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 120, alignment: .trailing)
            }

            applyButton(for: display, isActive: isActive, state: downloadState)
        }
        .padding(12)
        .glassEffect(.regular, in: .rect(cornerRadius: 10))
    }

    @ViewBuilder
    private func applyButton(for display: DisplayInfo, isActive: Bool, state: DownloadState?) -> some View {
        switch state {
        case .downloading:
            ProgressView()
                .controlSize(.small)
                .frame(minWidth: 72)
        case .failed(let message):
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .help(message)
                Button("Retry") {
                    applyToDisplay(display.id)
                }
                .buttonStyle(.glass)
            }
        default:
            if isActive {
                Button {
                    engine.stop(forDisplay: display.id)
                } label: {
                    Label("Remove", systemImage: "stop.circle")
                        .labelStyle(.titleOnly)
                        .frame(minWidth: 72)
                }
                .buttonStyle(.glass)
            } else {
                Button {
                    applyToDisplay(display.id)
                } label: {
                    Text("Apply")
                        .frame(minWidth: 72)
                }
                .buttonStyle(.glass)
            }
        }
    }

    // MARK: - Actions

    private func applyToAllDisplays() {
        let wp = wallpaper
        Task {
            if !wp.isLocal {
                await downloadManager.download(wallpaper: wp)
            }
            engine.apply(wp, scope: .allDisplays)
        }
    }

    private func applyToDisplay(_ displayID: String) {
        let wp = wallpaper
        Task {
            if !wp.isLocal {
                await downloadManager.download(wallpaper: wp)
            }
            engine.setWallpaper(wp, forDisplay: displayID)
        }
    }
}

// MARK: - FlowLayout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                anchor: .topLeading,
                proposal: .unspecified
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxLineWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                maxLineWidth = max(maxLineWidth, currentX - spacing)
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        maxLineWidth = max(maxLineWidth, currentX - spacing)
        let totalHeight = currentY + lineHeight
        return (CGSize(width: maxLineWidth, height: totalHeight), positions)
    }
}
