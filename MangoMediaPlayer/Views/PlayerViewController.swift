import UIKit
import AVFoundation
import GoogleInteractiveMediaAds

class PlayerViewController: UIViewController {
    private let videoURL: URL
    private let isSubscribed: Bool
    private var player: AVPlayer!
    private var playerLayer: AVPlayerLayer!
    private var playerItem: AVPlayerItem!
    private var adContainerView: UIView!
    private var adManager: AdManager?
    private var shouldRequestAd = true

    // Custom controls
    private var controlsContainer: UIView!
    private var playPauseButton: UIButton!
    private var seekSlider: UISlider!
    private var isControlsVisible = true
    private var timeObserverToken: Any?

    init(videoURL: URL, isSubscribed: Bool) {
        self.videoURL = videoURL
        self.isSubscribed = isSubscribed
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupPlayer()
        setupAdContainer()
        setupControls()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if shouldRequestAd {
            shouldRequestAd = false

            if isSubscribed {
                startMainVideo()
            } else {
                playAdThenMainVideo()
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        shouldRequestAd = true
    }

    private func setupPlayer() {
        player = AVPlayer()
        playerItem = AVPlayerItem(url: videoURL)
        player.replaceCurrentItem(with: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.bounds
        playerLayer.videoGravity = .resizeAspect
        view.layer.addSublayer(playerLayer)

        addPeriodicTimeObserver()
    }

    private func setupAdContainer() {
        adContainerView = UIView(frame: view.bounds)
        adContainerView.backgroundColor = .clear
        adContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(adContainerView)
        NSLayoutConstraint.activate([
            adContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            adContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            adContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            adContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupControls() {
        controlsContainer = UIView()
        controlsContainer.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        controlsContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlsContainer)

        NSLayoutConstraint.activate([
            controlsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlsContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            controlsContainer.heightAnchor.constraint(equalToConstant: 60)
        ])

        playPauseButton = UIButton(type: .system)
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playPauseButton.tintColor = .white
        playPauseButton.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)

        seekSlider = UISlider()
        seekSlider.addTarget(self, action: #selector(seekSliderChanged(_:)), for: .valueChanged)

        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        seekSlider.translatesAutoresizingMaskIntoConstraints = false

        controlsContainer.addSubview(playPauseButton)
        controlsContainer.addSubview(seekSlider)

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

    private func startMainVideo() {
        player.play()
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
    }

    private func playAdThenMainVideo() {
        // create a new AdManager instance every time
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

        let adTagUrl = "https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/vmap_ad_samples&sz=640x480&cust_params=sample_ar%3Dpremidpostpod&ciu_szs=300x250&gdfp_req=1&ad_rule=1&output=vmap&unviewed_position_start=1&env=vp&impl=s&cmsid=496&vid=short_onecue&correlator=\(Int(Date().timeIntervalSince1970))"

        adManager.requestAds(adTagUrl: adTagUrl)
    }

    @objc private func togglePlayPause() {
        if player.timeControlStatus == .playing {
            player.pause()
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        } else {
            player.play()
            playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        }
    }

    @objc private func seekSliderChanged(_ sender: UISlider) {
        let seconds = Double(sender.value)
        let targetTime = CMTime(seconds: seconds, preferredTimescale: 600)
        player.seek(to: targetTime)
    }

    private func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, let duration = self.player.currentItem?.duration.seconds, duration > 0 else { return }
            let current = time.seconds
            self.seekSlider.maximumValue = Float(duration)
            self.seekSlider.value = Float(current)
        }
    }

    deinit {
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
        }
    }
}
