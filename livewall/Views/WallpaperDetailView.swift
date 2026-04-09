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

    private var activeDisplayCount: Int {
        engine.activeWallpapers.values.filter { $0.id == wallpaper.id }.count
    }

    private var wallpaperSummary: String {
        if isStale {
            return "The source file is missing, so this entry can no longer be played."
        }
        if wallpaper.isLocal {
            return "Imported from your Mac and ready to apply anywhere."
        }
        if previewURL != nil {
            return "Cached locally for instant preview and faster applying."
        }
        return "Preview becomes fully interactive after the first download."
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                heroPreview

                summaryPanel

                if isStale {
                    staleNotice
                } else {
                    displayPicker
                }
            }
            .padding(24)
        }
        .frame(minWidth: 440, minHeight: 520)
    }

    private var summaryPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(wallpaper.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))

                    Text(wallpaperSummary)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                if activeDisplayCount > 0 {
                    Label("\(activeDisplayCount) active", systemImage: "play.circle.fill")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .glassEffect(.regular.tint(.green.opacity(0.24)), in: .capsule)
                }
            }

            HStack(spacing: 10) {
                detailPill(title: wallpaper.resolution.rawValue, systemImage: "display")
                if let duration = wallpaper.duration {
                    detailPill(title: String(format: "%.0fs loop", duration), systemImage: "clock")
                }
                detailPill(
                    title: wallpaper.isLocal ? "Imported" : (previewURL != nil ? "Cached" : "Download on apply"),
                    systemImage: wallpaper.isLocal ? "folder.fill" : "arrow.down.circle"
                )
            }

            if !wallpaper.tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(wallpaper.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .glassEffect(.regular, in: .capsule)
                    }
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.68),
                            Color(nsColor: .windowBackgroundColor).opacity(0.90)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.30), lineWidth: 1)
                }
        }
    }

    private func detailPill(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .glassEffect(.regular, in: .capsule)
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
            .overlay(alignment: .topLeading) {
                HStack(spacing: 8) {
                    detailPill(
                        title: wallpaper.isLocal ? "Imported" : "Catalog",
                        systemImage: wallpaper.isLocal ? "folder.fill" : "sparkles.rectangle.stack.fill"
                    )
                    if previewURL != nil {
                        detailPill(title: "Ready to preview", systemImage: "play.circle.fill")
                    }
                }
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
                if let fraction = downloadManager.downloads[wallpaper.id]?.progressFraction {
                    ProgressView(value: fraction) {
                        Text("Downloading preview…")
                            .foregroundStyle(.white)
                    }
                    .progressViewStyle(.linear)
                    .tint(.white)
                    .frame(maxWidth: 220)
                    .padding(.horizontal, 24)
                } else {
                    ProgressView("Downloading preview…")
                        .controlSize(.regular)
                        .foregroundStyle(.white)
                }
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
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apply to Display")
                        .font(.headline)
                    Text("Choose where this wallpaper should play right now.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

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
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
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
                .foregroundStyle(
                    isActive
                        ? AnyShapeStyle(.tint)
                        : AnyShapeStyle(.secondary)
                )
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(display.localizedName)
                    .font(.system(size: 13, weight: .medium))
                Text(String(format: "%.0f × %.0f", display.resolution.width, display.resolution.height))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if isActive {
                    Label("Currently Live", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
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
        }
        .padding(14)
        .glassEffect(
            isActive ? .regular.tint(.green.opacity(0.16)) : .regular,
            in: .rect(cornerRadius: 16)
        )
    }

    @ViewBuilder
    private func applyButton(for display: DisplayInfo, isActive: Bool, state: DownloadState?) -> some View {
        switch state {
        case .downloading(let fraction):
            ProgressView(value: fraction)
                .progressViewStyle(.linear)
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
                .buttonStyle(.glassProminent)
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
