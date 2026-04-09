import AppKit
import Combine
import IOKit.ps

enum WallpaperApplyScope {
    case allDisplays
    case specificDisplay(displayID: String)
}

final class WallpaperEngine: ObservableObject {
    static let shared: WallpaperEngine = {
        let dm = DisplayManager()
        return WallpaperEngine(displayManager: dm)
    }()

    @Published var activeWallpapers: [String: Wallpaper] = [:]
    @Published var isPaused = false

    private var windows: [String: WallpaperWindow] = [:]
    private var displayManager: DisplayManager
    private var powerPollTimer: Timer?

    init(displayManager: DisplayManager) {
        self.displayManager = displayManager
        setupBatteryMonitoring()
    }

    deinit {
        powerPollTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    static func makeDefault() -> WallpaperEngine {
        WallpaperEngine(displayManager: DisplayManager())
    }

    func apply(_ wallpaper: Wallpaper, scope: WallpaperApplyScope) {
        print("[Engine] apply: \(wallpaper.title), displays=\(displayManager.displays.count)")
        print("[Engine] Display list: \(displayManager.displays.map { "\($0.localizedName) \($0.frame)" })")
        switch scope {
        case .allDisplays:
            for display in displayManager.displays {
                print("[Engine] Applying to display \(display.id) (\(display.localizedName))")
                setWallpaper(wallpaper, forDisplay: display.id)
            }
        case .specificDisplay(let displayID):
            setWallpaper(wallpaper, forDisplay: displayID)
        }
    }

    func setWallpaper(_ wallpaper: Wallpaper, forDisplay displayID: String) {
        activeWallpapers[displayID] = wallpaper
        updateWindow(forDisplay: displayID, wallpaper: wallpaper)
    }

    func pauseAll() {
        isPaused = true
        windows.values.forEach { $0.pause() }
    }

    func resumeAll() {
        isPaused = false
        windows.values.forEach { $0.resume() }
    }

    func stopAll() {
        windows.values.forEach { $0.stop() }
        windows.values.forEach { $0.orderOut(nil) }
        windows.removeAll()
        activeWallpapers.removeAll()
    }

    /// Removes the wallpaper from a specific display, hiding its window.
    func stop(forDisplay displayID: String) {
        if let window = windows[displayID] {
            window.stop()
            window.orderOut(nil)
            windows.removeValue(forKey: displayID)
        }
        activeWallpapers.removeValue(forKey: displayID)
    }

    func refreshDisplays() {
        displayManager.refreshDisplays()
        rebuildWindows()
    }

    var displays: [DisplayInfo] {
        displayManager.displays
    }

    private func updateWindow(forDisplay displayID: String, wallpaper: Wallpaper) {
        guard let display = displayManager.displays.first(where: { $0.id == displayID }) else {
            print("[Engine] No display found for \(displayID)")
            return
        }

        print("[Engine] updateWindow: display=\(displayID) frame=\(display.frame)")

        let window: WallpaperWindow
        if let existing = windows[displayID] {
            window = existing
        } else {
            window = WallpaperWindow(contentRect: display.frame)
            windows[displayID] = window
            print("[Engine] Created WallpaperWindow")
        }

        window.updateFrame(display.frame)

        let url: URL
        if let localURL = wallpaper.localFileURL {
            url = localURL
            print("[Engine] Playing local: \(url.path)")
        } else {
            // Check download directory for cached file
            let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let downloadDir = support.appendingPathComponent("livewall/wallpapers", isDirectory: true)
            let cachedURL = downloadDir.appendingPathComponent("\(wallpaper.id).mp4")

            if FileManager.default.fileExists(atPath: cachedURL.path) {
                url = cachedURL
                print("[Engine] Playing cached: \(url.path)")
            } else if let remoteURL = wallpaper.remoteURL {
                url = remoteURL
                print("[Engine] Playing remote: \(url)")
            } else if let videoURL = URL(string: wallpaper.videoURL) {
                url = videoURL
                print("[Engine] Playing videoURL: \(url)")
            } else {
                print("[Engine] No valid URL!")
                return
            }
        }

        window.play(url: url)
        window.orderBack(nil)
        print("[Engine] WallpaperWindow: visible=\(window.isVisible) frame=\(window.frame) level=\(window.level.rawValue)")
    }

    private func rebuildWindows() {
        let currentDisplayIDs = Set(displayManager.displays.map { $0.id })
        let staleIDs = Set(windows.keys).subtracting(currentDisplayIDs)

        for staleID in staleIDs {
            windows[staleID]?.stop()
            windows[staleID]?.close()
            windows.removeValue(forKey: staleID)
            activeWallpapers.removeValue(forKey: staleID)
        }

        for display in displayManager.displays {
            if let wallpaper = activeWallpapers[display.id] {
                updateWindow(forDisplay: display.id, wallpaper: wallpaper)
            }
        }
    }

    private func setupBatteryMonitoring() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handlePowerChange()
        }

        NotificationCenter.default.addObserver(
            forName: .NSProcessInfoPowerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handlePowerChange()
        }

        // Poll every 30s to catch plug/unplug events between notifications.
        powerPollTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.handlePowerChange()
        }
    }

    private func handlePowerChange() {
        guard SettingsManager.shared.pauseOnBattery else { return }

        let onBattery = ProcessInfo.processInfo.isLowPowerModeEnabled || isOnBattery()

        if onBattery {
            pauseAll()
        } else {
            resumeAll()
        }
    }

    private func isOnBattery() -> Bool {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
            return false
        }
        guard let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else {
            return false
        }

        for source in sources {
            guard let desc = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
                  let type = desc[kIOPSPowerSourceStateKey] as? String else {
                continue
            }
            if type == kIOPSOffLineValue {
                return true
            }
        }
        return false
    }
}
