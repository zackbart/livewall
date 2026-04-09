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
        GridItem(.adaptive(minimum: 190, maximum: 230), spacing: 22)
    ]

    var body: some View {
        Group {
            if let selected = selectedWallpaper {
                detailPane(for: selected)
            } else {
                galleryPane
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

    @ViewBuilder
    private var galleryPane: some View {
        Group {
            if filteredWallpapers.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                        if !engine.activeWallpapers.isEmpty {
                            nowPlayingSection
                        }

                        Section {
                            LazyVGrid(columns: columns, spacing: 22) {
                                ForEach(filteredWallpapers) { wallpaper in
                                    WallpaperCardView(
                                        wallpaper: wallpaper,
                                        isActive: activeWallpaperIDs.contains(wallpaper.id),
                                        isStale: catalog.staleLocalWallpaperIDs.contains(wallpaper.id)
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.18)) {
                                            selectedWallpaper = wallpaper
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        } header: {
                            if !catalog.allTags.isEmpty {
                                tagFilterStrip
                            }
                        }
                    }
                    .padding(.top, 8)
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
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    openWindow(id: "import")
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
                .help("Import a video from your Mac — or drop one onto the window")

                Button {
                    openWindow(id: "settings")
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                .help("Preferences and displays")
            }
        }
        .navigationTitle("LiveWall")
    }

    // MARK: - Now Playing

    private var nowPlayingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Label("Now Playing", systemImage: "dot.radiowaves.left.and.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
                Button(engine.isPaused ? "Resume" : "Pause All") {
                    if engine.isPaused {
                        engine.resumeAll()
                    } else {
                        engine.pauseAll()
                    }
                }
                .buttonStyle(.glass)
                .controlSize(.small)
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
                .padding(.bottom, 4)
            }
        }
        .padding(.top, 4)
    }

    private func nowPlayingCard(displayID: String, wallpaper: Wallpaper) -> some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    selectedWallpaper = wallpaper
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "display")
                        .font(.title3)
                        .foregroundStyle(.tint)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(wallpaper.title)
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                        Text(displayName(for: displayID))
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(minWidth: 120, alignment: .leading)
                }
            }
            .buttonStyle(.plain)

            Button {
                engine.stop(forDisplay: displayID)
            } label: {
                Image(systemName: "stop.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Remove wallpaper from \(displayName(for: displayID))")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: .rect(cornerRadius: 10))
    }

    private func displayName(for id: String) -> String {
        engine.displays.first(where: { $0.id == id })?.localizedName ?? "Display"
    }

    // MARK: - Tag strip

    private var tagFilterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                tagChip(title: "All", tag: "")
                ForEach(catalog.allTags, id: \.self) { tag in
                    tagChip(title: tag, tag: tag)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .background(alignment: .bottom) {
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(Color(nsColor: .windowBackgroundColor))
                    .ignoresSafeArea(edges: .horizontal)
                Rectangle()
                    .fill(.regularMaterial)
                    .ignoresSafeArea(edges: .horizontal)
                Divider()
                    .ignoresSafeArea(edges: .horizontal)
            }
        }
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
            HStack(spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedWallpaper = nil
                    }
                } label: {
                    Label("Gallery", systemImage: "chevron.left")
                }
                .buttonStyle(.glass)
                .controlSize(.regular)
                .keyboardShortcut(.cancelAction)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)

            WallpaperDetailView(wallpaper: wallpaper) {
                withAnimation(.easeInOut(duration: 0.18)) {
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
                     : "Try a different search term or tag.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
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
