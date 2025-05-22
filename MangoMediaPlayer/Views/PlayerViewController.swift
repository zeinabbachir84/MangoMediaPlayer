
import UIKit
import AVFoundation
import GoogleInteractiveMediaAds

/// A view controller that manages HLS video playback with custom controls and Google IMA ads.
/// It handles pre-roll, mid-roll, and post-roll ads, and resumes content seamlessly.
class PlayerViewController: UIViewController {
    // MARK: - Configuration Properties

    /// URL of the video to play
    private let videoURL: URL
    /// Whether the user is subscribed (skips ads if true)
    private let isSubscribed: Bool

    // MARK: - AVPlayer Properties

    private var player: AVPlayer!
    private var playerLayer: AVPlayerLayer!
    private var playerItem: AVPlayerItem!

    // MARK: - Ad Properties

    /// Container view for rendering ads on top of the player
    private var adContainerView: UIView!
    /// Manages loading and playback of interactive media ads
    private var adManager: AdManager?
    /// Controls whether to request ads (reset each appearance)
    private var shouldRequestAd = true

    // MARK: - Custom Control UI

    private var controlsContainer: UIView!
    private var playPauseButton: UIButton!
    private var seekSlider: UISlider!
    private var timeObserverToken: Any?

    // MARK: - Initialization

    /// Initializes the controller with video URL and subscription state
    init(videoURL: URL, isSubscribed: Bool) {
        self.videoURL = videoURL
        self.isSubscribed = isSubscribed
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        // We don't support storyboard initialization
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black  // Set background to black

        setupPlayer()         // Configure AVPlayer and its layer
        setupAdContainer()    // Create ad container overlay
        setupControls()       // Add play/pause and seek bar
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reset ad request flag each time the view appears
        shouldRequestAd = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Only request and play ads once per appearance
        if shouldRequestAd {
            shouldRequestAd = false
            if isSubscribed {
                startMainVideo()  // No ads for subscribed users
            } else {
                playAdThenMainVideo()  // Load and play ads first
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure the player layer always fills the view bounds
        playerLayer.frame = view.bounds
    }

    // MARK: - Setup Methods

    /// Configures AVPlayer, AVPlayerItem, and AVPlayerLayer
    private func setupPlayer() {
        player = AVPlayer()
        playerItem = AVPlayerItem(url: videoURL)
        player.replaceCurrentItem(with: playerItem)

        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        playerLayer.frame = view.bounds
        view.layer.addSublayer(playerLayer)

        // Observe time updates to update UI
        addPeriodicTimeObserver()
    }

    /// Creates an invisible container view for ad playback overlay
    private func setupAdContainer() {
        adContainerView = UIView(frame: view.bounds)
        adContainerView.backgroundColor = .clear
        adContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(adContainerView)
        // Pin ad container to all edges
        NSLayoutConstraint.activate([
            adContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            adContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            adContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            adContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    /// Builds the bottom control bar with play/pause and seek slider
    private func setupControls() {
        // Semi-transparent background for controls
        controlsContainer = UIView()
        controlsContainer.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        controlsContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlsContainer)

        // Position controls at the bottom safe area
        NSLayoutConstraint.activate([
            controlsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlsContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            controlsContainer.heightAnchor.constraint(equalToConstant: 60)
        ])

        // Play/Pause button
        playPauseButton = UIButton(type: .system)
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playPauseButton.tintColor = .white
        playPauseButton.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)

        // Slider for seeking
        seekSlider = UISlider()
        seekSlider.addTarget(self, action: #selector(seekSliderChanged(_:)), for: .valueChanged)

        // Enable Auto Layout for subviews
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        seekSlider.translatesAutoresizingMaskIntoConstraints = false
        controlsContainer.addSubview(playPauseButton)
        controlsContainer.addSubview(seekSlider)

        // Layout play button and slider within the container
        NSLayoutConstraint.activate([
            playPauseButton.leadingAnchor.constraint(equalTo: controlsContainer.leadingAnchor, constant: 16),
            playPauseButton.centerYAnchor.constraint(equalTo: controlsContainer.centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 40),
            playPauseButton.heightAnchor.constraint(equalToConstant: 40),

            seekSlider.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 12),
            seekSlider.trailingAnchor.constraint(equalTo: controlsContainer.trailingAnchor, constant: -16),
            seekSlider.centerYAnchor.constraint(equalTo: controlsContainer.centerYAnchor)
        ])
    }

    // MARK: - Playback Methods

    /// Starts the main content video (skipping ads)
    private func startMainVideo() {
        player.play()
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
    }

    /// Loads and plays ads, then resumes content when finished
    private func playAdThenMainVideo() {
        // Generate a fresh correlator to avoid cached ads
        let correlator = Int(Date().timeIntervalSince1970)
        let adTagUrl = "https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/vmap_ad_samples&sz=640x480&cust_params=sample_ar%3Dpremidpostpod&ciu_szs=300x250&gdfp_req=1&ad_rule=1&output=vmap&unviewed_position_start=1&env=vp&impl=s&cmsid=496&vid=short_onecue&correlator=\(correlator)"

        // Create a new AdManager for each ad playback session
        let adManager = AdManager(
            player: player,
            viewController: self,
            adContainerView: adContainerView,
            onAdFinished: { [weak self] in
                DispatchQueue.main.async {
                    self?.startMainVideo()
                }
            }
        )
        self.adManager = adManager
        adManager.requestAds(adTagUrl: adTagUrl)
    }

    // MARK: - Control Actions

    /// Toggle between play and pause states
    @objc private func togglePlayPause() {
        if player.timeControlStatus == .playing {
            player.pause()
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        } else {
            player.play()
            playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        }
    }

    /// Seek video to the slider position
    @objc private func seekSliderChanged(_ sender: UISlider) {
        let seconds = Double(sender.value)
        let targetTime = CMTime(seconds: seconds, preferredTimescale: 600)
        player.seek(to: targetTime)
    }

    /// Adds a periodic time observer to update the seek slider
    private func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self,
                  let duration = self.player.currentItem?.duration.seconds,
                  duration > 0 else { return }
            self.seekSlider.maximumValue = Float(duration)
            self.seekSlider.value = Float(time.seconds)
        }
    }

    deinit {
        // Clean up time observer to prevent memory leaks
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
        }
    }
}
