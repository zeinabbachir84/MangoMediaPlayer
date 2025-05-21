//
//  AdManager.swift
//  MangoMediaPlayer
//
//  Created by Zeinab Bachir on 21/05/2025.
//

import UIKit
import GoogleInteractiveMediaAds
import AVFoundation

class AdManager: NSObject {
    private var adsLoader: IMAAdsLoader!
    private var adsManager: IMAAdsManager?
    private let player: AVPlayer
    private let adContainerView: UIView
    private weak var viewController: UIViewController?
    private var contentPlayhead: IMAAVPlayerContentPlayhead?
    private let onAdFinished: () -> Void

    init(player: AVPlayer,
         viewController: UIViewController,
         adContainerView: UIView,
         onAdFinished: @escaping () -> Void) {
        self.player = player
        self.viewController = viewController
        self.adContainerView = adContainerView
        self.onAdFinished = onAdFinished
        super.init()
        setupIMA()
    }

    private func setupIMA() {
        let settings = IMASettings()
        adsLoader = IMAAdsLoader(settings: settings)
        adsLoader.delegate = self
        contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: player)
    }

    func requestAds(adTagUrl: String) {
        guard let viewController = viewController else {
            print("Error: viewController is nil.")
            return
        }

        let adDisplayContainer = IMAAdDisplayContainer(
            adContainer: adContainerView,
            viewController: viewController,
            companionSlots: nil
        )

        let request = IMAAdsRequest(
            adTagUrl: adTagUrl,
            adDisplayContainer: adDisplayContainer,
            contentPlayhead: contentPlayhead,
            userContext: nil
        )

        adsLoader.requestAds(with: request)
    }
}

extension AdManager: IMAAdsLoaderDelegate {
    func adsLoader(_ loader: IMAAdsLoader, adsLoadedWith adsLoadedData: IMAAdsLoadedData) {
        adsManager = adsLoadedData.adsManager
        adsManager?.delegate = self

        if let cuePoints = adsManager?.adCuePoints {
            for (index, cuePoint) in cuePoints.enumerated() {
                if cuePoint is NSNull {
                    print("Cue Point \(index): Pre-roll or Post-roll")
                } else if let time = cuePoint as? TimeInterval {
                    print("Cue Point \(index): Mid-roll at \(time) seconds")
                } else {
                    print("Cue Point \(index): Unknown type: \(type(of: cuePoint))")
                }
            }
        }

        let adsRenderingSettings = IMAAdsRenderingSettings()
        adsManager?.initialize(with: adsRenderingSettings)
    }


    func adsLoader(_ loader: IMAAdsLoader, failedWith adErrorData: IMAAdLoadingErrorData) {
        print("Ad loading failed: \(adErrorData.adError.message ?? "Unknown error")")
        onAdFinished() // fallback to content
    }
}

extension AdManager: IMAAdsManagerDelegate {
    func adsManager(_ adsManager: IMAAdsManager, didReceive event: IMAAdEvent) {
        print("Ad Event: \(event.type.rawValue)")

        switch event.type {
        case .LOADED:
            adsManager.start()
        case .ALL_ADS_COMPLETED:
            onAdFinished()
        default:
            break
        }
    }

    func adsManager(_ adsManager: IMAAdsManager, didReceive error: IMAAdError) {
        print("Ad playback error: \(error.message ?? "Unknown error")")
        self.adsManager?.destroy()
        self.adsManager = nil
        onAdFinished()
    }

    func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager) {
        print("🔴 Requesting content pause for ad")
        player.pause()
        player.rate = 0.0 // Enforces no playback
    }

    func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager) {
        player.play()
    }
}
