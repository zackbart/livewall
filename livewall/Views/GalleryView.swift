import SwiftUI
import UniformTypeIdentifiers

struct GalleryView: View {
    @State private var selectedWallpaper: Wallpaper?
    @State private var searchQuery = ""
    @State private var selectedTag: String = ""
    @State private var showWelcome = false
    @State private var isDropTargeted = false

    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false

    @Environment(\.openWindow) private var openWindow

    @ObservedObject private var catalog = WallpaperCatalog.shared
    @ObservedObject private var engine = WallpaperEngine.shared
    @ObservedObject private var downloadManager = DownloadManager.shared

    private let columns = [
        GridItem(.adaptive(minimum: 220, maximum: 260), spacing: 28)
    ]

    var body: some View {
        ZStack {
            AppAmbientBackground()

            Group {
                if let selected = selectedWallpaper {
                    detailPane(for: selected)
                } else {
                    galleryPane
                }
            }
        }
        .frame(minWidth: 760, minHeight: 560)
        .sheet(isPresented: $showWelcome) {
            WelcomeSheet(onDismiss: {
                hasSeenWelcome = true
                showWelcome = false
            })
        }
        .onAppear {
            if !hasSeenWelcome {
                // Defer to next runloop so the sheet lands after the window is presented.
                DispatchQueue.main.async {
                    showWelcome = true
                }
            }
        }
    }

    // MARK: - Gallery

    private var activeWallpaperIDs: Set<String> {
        Set(engine.activeWallpapers.values.map(\.id))
    }

    private var localWallpaperCount: Int {
        catalog.allWallpapers.filter(\.isLocal).count
    }

    private var displayCount: Int {
        max(engine.displays.count, 1)
    }

    @ViewBuilder
    private var galleryPane: some View {
        Group {
            if filteredWallpapers.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
                        heroSection

                        if !engine.activeWallpapers.isEmpty {
                            nowPlayingSection
                        }

                        Section {
                            LazyVGrid(columns: columns, spacing: 28) {
                                ForEach(filteredWallpapers) { wallpaper in
                                    WallpaperCardView(
                                        wallpaper: wallpaper,
                                        isActive: activeWallpaperIDs.contains(wallpaper.id),
                                        isStale: catalog.staleLocalWallpaperIDs.contains(wallpaper.id)
                                    ) {
                                        withAnimation(.spring(duration: 0.35, bounce: 0.1)) {
                                            selectedWallpaper = wallpaper
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        } header: {
                            if !catalog.allTags.isEmpty || !searchQuery.isEmpty {
                                tagFilterStrip
                            }
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 28)
                }
            }
        }
        .searchable(
            text: $searchQuery,
            placement: .toolbar,
            prompt: "Search wallpapers"
        )
        .onDrop(of: [UTType.movie.identifier, UTType.mpeg4Movie.identifier, UTType.quickTimeMovie.identifier], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
        .overlay {
            if isDropTargeted {
                dropTargetOverlay
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Label("LiveWall", systemImage: "sparkles.tv.fill")
                    .font(.headline.weight(.semibold))
            }

            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    openWindow(id: "import")
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.glassProminent)
                .help("Import a video from your Mac — or drop one onto the window")

                Button {
                    openWindow(id: "settings")
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                .buttonStyle(.glass)
                .help("Preferences and displays")
            }
        }
        .navigationTitle("LiveWall")
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Make your desktop feel alive.")
                        .font(.system(size: 30, weight: .bold, design: .rounded))

                    Text("Browse the catalog, import your own loops, and send motion to every display without turning the app chrome into a frosted mess.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 10) {
                    heroMetric(
                        value: "\(catalog.allWallpapers.count)",
                        title: "Wallpapers",
                        systemImage: "rectangle.stack.fill"
                    )
                    heroMetric(
                        value: "\(displayCount)",
                        title: displayCount == 1 ? "Display Ready" : "Displays Ready",
                        systemImage: "display.2"
                    )
                }
            }

            HStack(spacing: 10) {
                Button {
                    openWindow(id: "import")
                } label: {
                    Label("Import a Video", systemImage: "square.and.arrow.down")
                        .frame(minWidth: 148)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)

                Button {
                    openWindow(id: "settings")
                } label: {
                    Label("Tune Playback", systemImage: "slider.horizontal.3")
                }
                .buttonStyle(.glass)
                .controlSize(.large)
            }

            HStack(spacing: 10) {
                spotlightPill(
                    title: activeWallpaperIDs.isEmpty ? "Ready to apply" : "\(activeWallpaperIDs.count) active",
                    systemImage: activeWallpaperIDs.isEmpty ? "sparkles" : "play.circle.fill"
                )
                spotlightPill(
                    title: "\(localWallpaperCount) imported",
                    systemImage: "folder.fill"
                )
                spotlightPill(
                    title: "Hover for motion",
                    systemImage: "cursorarrow.motionlines"
                )
            }
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.72),
                            Color(nsColor: .windowBackgroundColor).opacity(0.88),
                            Color.accentColor.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.06), radius: 18, x: 0, y: 10)
        }
        .padding(.horizontal, 20)
    }

    private func heroMetric(value: String, title: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(.tint)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.headline.weight(.semibold))
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .capsule)
    }

    private func spotlightPill(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .glassEffect(.regular, in: .capsule)
    }

    // MARK: - Now Playing

    private var nowPlayingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Now Playing")
                        .font(.title3.weight(.semibold))

                    Text(engine.isPaused ? "Playback is paused across your desktop." : "Quick access to every live wallpaper currently running.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(engine.isPaused ? "Resume All" : "Pause All") {
                    if engine.isPaused {
                        engine.resumeAll()
                    } else {
                        engine.pauseAll()
                    }
                }
                .buttonStyle(.glass)
                .controlSize(.regular)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(engine.activeWallpapers.keys.sorted()), id: \.self) { displayID in
                        if let wp = engine.activeWallpapers[displayID] {
                            nowPlayingCard(displayID: displayID, wallpaper: wp)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 6)
            }
        }
        .padding(.top, 2)
    }

    private func nowPlayingCard(displayID: String, wallpaper: Wallpaper) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(duration: 0.35, bounce: 0.1)) {
                    selectedWallpaper = wallpaper
                }
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "display")
                            .font(.title3)
                            .foregroundStyle(.tint)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(displayName(for: displayID))
                                .font(.system(size: 12, weight: .semibold))
                            Text(wallpaper.title)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }

                    HStack(spacing: 8) {
                        spotlightPill(
                            title: wallpaper.isLocal ? "Imported" : "Catalog",
                            systemImage: wallpaper.isLocal ? "folder" : "sparkles.rectangle.stack"
                        )

                        if let duration = wallpaper.duration {
                            spotlightPill(
                                title: String(format: "%.0fs loop", duration),
                                systemImage: "clock"
                            )
                        }
                    }
                }
                .frame(width: 220, alignment: .leading)
            }
            .buttonStyle(.plain)

            HStack {
                Button {
                    engine.stop(forDisplay: displayID)
                } label: {
                    Label("Remove", systemImage: "stop.circle")
                }
                .buttonStyle(.glass)
                .controlSize(.small)
                .help("Remove wallpaper from \(displayName(for: displayID))")

                Spacer()

                Image(systemName: "waveform")
                    .font(.caption)
                    .foregroundStyle(
                        engine.isPaused
                            ? AnyShapeStyle(.secondary)
                            : AnyShapeStyle(.tint)
                    )
            }
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }

    private func displayName(for id: String) -> String {
        engine.displays.first(where: { $0.id == id })?.localizedName ?? "Display"
    }

    // MARK: - Tag strip

    private var tagFilterStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(searchQuery.isEmpty ? "Filter by vibe" : "Refine your search")
                        .font(.headline)
                    Text(selectedTag.isEmpty ? "Choose a tag to tighten the gallery." : "Showing \(selectedTag.lowercased()) wallpapers.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(filteredWallpapers.count) shown")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .glassEffect(.regular, in: .capsule)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    tagChip(title: "All", tag: "")
                    ForEach(catalog.allTags, id: \.self) { tag in
                        tagChip(title: tag, tag: tag)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
        }
        .padding(.top, 4)
        .background(Color.clear)
    }

    private func tagChip(title: String, tag: String) -> some View {
        let isSelected = selectedTag == tag
        return Button {
            withAnimation(.easeOut(duration: 0.15)) {
                selectedTag = tag
            }
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .glassEffect(
            isSelected ? .regular.tint(.accentColor.opacity(0.55)) : .regular,
            in: .capsule
        )
        .foregroundStyle(isSelected ? Color.white : .primary)
    }

    // MARK: - Detail

    @ViewBuilder
    private func detailPane(for wallpaper: Wallpaper) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button {
                    withAnimation(.spring(duration: 0.35, bounce: 0.05)) {
                        selectedWallpaper = nil
                    }
                } label: {
                    Label("Gallery", systemImage: "chevron.left")
                }
                .buttonStyle(.glass)
                .controlSize(.regular)
                .keyboardShortcut(.cancelAction)

                Text(wallpaper.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                if activeWallpaperIDs.contains(wallpaper.id) {
                    Label("Live on your desktop", systemImage: "play.circle.fill")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .glassEffect(.regular.tint(.green.opacity(0.28)), in: .capsule)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)

            WallpaperDetailView(wallpaper: wallpaper) {
                withAnimation(.spring(duration: 0.35, bounce: 0.05)) {
                    selectedWallpaper = nil
                }
            }
        }
    }

    // MARK: - Data

    private var filteredWallpapers: [Wallpaper] {
        var results = catalog.allWallpapers

        if !searchQuery.isEmpty {
            results = catalog.search(query: searchQuery)
        }

        if !selectedTag.isEmpty {
            results = results.filter { $0.tags.contains(selectedTag) }
        }

        return results
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 22) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 56, weight: .light))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.tint)

                VStack(spacing: 6) {
                    Text(searchQuery.isEmpty ? "Start Your Collection" : "No Matches")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(searchQuery.isEmpty
                         ? "Import a video from your Mac, or drop an MP4 or MOV onto this window."
                         : "Try a different search term or clear the active tag filter.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 380)
                }

                HStack(spacing: 10) {
                    spotlightPill(title: "MP4 + MOV", systemImage: "film")
                    spotlightPill(title: "Hover previews", systemImage: "cursorarrow.motionlines")
                    spotlightPill(title: "Multi-display", systemImage: "display.2")
                }

                if searchQuery.isEmpty {
                    Button {
                        openWindow(id: "import")
                    } label: {
                        Label("Import Wallpaper", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(30)
            .background {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.74),
                                Color(nsColor: .windowBackgroundColor).opacity(0.92)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.32), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 12)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    // MARK: - Drop target overlay

    private var dropTargetOverlay: some View {
        ZStack {
            Color.black.opacity(0.35)

            VStack(spacing: 14) {
                Image(systemName: "square.and.arrow.down.on.square.fill")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(.white)

                Text("Drop to Import")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .padding(40)
            .glassEffect(.regular.tint(.accentColor.opacity(0.5)), in: .rect(cornerRadius: 20))
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .transition(.opacity)
    }

    // MARK: - Drop handler

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else {
            AppErrorPresenter.report(
                title: "Couldn't Import",
                message: "No file was dropped.",
                recoverySuggestion: "Try dragging the video file again."
            )
            return false
        }

        let targetTypes = [UTType.quickTimeMovie.identifier, UTType.mpeg4Movie.identifier, UTType.movie.identifier]
        guard let matchingType = targetTypes.first(where: { provider.hasItemConformingToTypeIdentifier($0) }) else {
            AppErrorPresenter.report(
                title: "Unsupported File",
                message: "That file isn't a supported video format.",
                recoverySuggestion: "Drop an MP4 or MOV file."
            )
            return false
        }

        provider.loadItem(forTypeIdentifier: matchingType, options: nil) { item, error in
            if let error = error {
                AppErrorPresenter.report(
                    title: "Couldn't Import",
                    message: error.localizedDescription,
                    recoverySuggestion: "Try dragging the file again."
                )
                return
            }

            var url: URL?
            if let directURL = item as? URL {
                url = directURL
            } else if let data = item as? Data {
                url = URL(dataRepresentation: data, relativeTo: nil)
            }

            guard let fileURL = url else {
                AppErrorPresenter.report(
                    title: "Couldn't Import",
                    message: "Couldn't read the dropped file's location.",
                    recoverySuggestion: "Try importing via the toolbar button instead."
                )
                return
            }

            Task { @MainActor in
                // catalog.addLocalWallpaper surfaces its own errors via the presenter on failure.
                if let wallpaper = await catalog.addLocalWallpaper(fileURL: fileURL) {
                    engine.apply(wallpaper, scope: .allDisplays)
                }
            }
        }

        return true
    }
}
