//
//  PlayerViewController.swift
//  MangoMediaPlayer
//
//  Created by Zeinab Bachir on 21/05/2025.
//

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

    private func setupPlayer() {
        player = AVPlayer()
        playerItem = AVPlayerItem(url: videoURL)
        player.replaceCurrentItem(with: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.bounds
        playerLayer.videoGravity = .resizeAspect
        view.layer.addSublayer(playerLayer)
    }

    private func setupAdContainer() {
        adContainerView = UIView(frame: view.bounds)
        adContainerView.backgroundColor = .clear
        adContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(adContainerView)
        view.bringSubviewToFront(adContainerView)
        NSLayoutConstraint.activate([
            adContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            adContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            adContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            adContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func startMainVideo() {
        player.play()
    }

    private func playAdThenMainVideo() {
        adManager = AdManager(
            player: player,
            viewController: self,
            adContainerView: adContainerView,
            onAdFinished: { [weak self] in
                DispatchQueue.main.async {
                    self?.startMainVideo()
                }
            }
        )

        let adTagUrl = "https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/vmap_ad_samples&sz=640x480&cust_params=sample_ar%3Dpremidpostpod&ciu_szs=300x250&gdfp_req=1&ad_rule=1&output=vmap&unviewed_position_start=1&env=vp&impl=s&cmsid=496&vid=short_onecue&correlator="

        adManager?.requestAds(adTagUrl: adTagUrl)
    }
}
