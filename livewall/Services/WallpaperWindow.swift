import AppKit
import AVFoundation

final class WallpaperPlayerView: NSView {
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var notificationObserver: NSObjectProtocol?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layerContentsRedrawPolicy = .never
        autoresizingMask = [.width, .height]

        let layer = AVPlayerLayer()
        layer.videoGravity = .resizeAspectFill
        layer.frame = bounds
        layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        self.layer?.addSublayer(layer)
        playerLayer = layer
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func play(url: URL) {
        stop()

        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.actionAtItemEnd = .none
        newPlayer.isMuted = true

        playerLayer?.player = newPlayer
        player = newPlayer

        notificationObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            playerItem.seek(to: .zero) { _ in
                newPlayer.play()
            }
        }

        newPlayer.play()
    }

    func pause() {
        player?.pause()
    }

    func resume() {
        player?.play()
    }

    func stop() {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
            notificationObserver = nil
        }
        player?.pause()
        playerLayer?.player = nil
        player = nil
    }

    override func layout() {
        super.layout()
        playerLayer?.frame = bounds
    }
}

final class WallpaperWindow: NSWindow {
    let playerView: WallpaperPlayerView

    init(contentRect: CGRect) {
        playerView = WallpaperPlayerView(frame: NSRect(origin: .zero, size: contentRect.size))

        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        configureWindow()
    }

    private func configureWindow() {
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        isOpaque = true
        backgroundColor = .black
        ignoresMouseEvents = true
        collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle,
            .fullScreenAuxiliary
        ]
        hasShadow = false
        isReleasedWhenClosed = false
        acceptsMouseMovedEvents = false
        canHide = false
        hidesOnDeactivate = false
        animationBehavior = .none

        contentView = playerView
    }

    func play(url: URL) {
        playerView.play(url: url)
    }

    func pause() {
        playerView.pause()
    }

    func resume() {
        playerView.resume()
    }

    func stop() {
        playerView.stop()
    }

    func updateFrame(_ rect: CGRect) {
        setFrame(rect, display: true)
    }
}
