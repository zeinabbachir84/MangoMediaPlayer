//
//  AdManager.swift
//  MangoMediaPlayer
//
//  Created by Zeinab Bachir on 21/05/2025.
//

import UIKit
import GoogleInteractiveMediaAds
import AVFoundation

/// Manages loading and playback of Google IMA ads (pre-roll, mid-roll, post-roll)
/// and resumes the main video content when ads finish or fail.
class AdManager: NSObject {
    // MARK: - Private Properties

    /// IMA SDK loader responsible for fetching ad resources
    private var adsLoader: IMAAdsLoader!
    /// Manages ad playback lifecycle and events
    private var adsManager: IMAAdsManager?

    /// The AVPlayer instance playing the main content
    private let player: AVPlayer
    /// The view where ads will be rendered on top of video
    private let adContainerView: UIView
    /// Weak reference to the view controller to present UI and handle callbacks
    private weak var viewController: UIViewController?
    /// Tracks content playhead for synchronized ad insertion
    private var contentPlayhead: IMAAVPlayerContentPlayhead?

    /// Closure called when all ads finish or fail, to resume content playback
    private let onAdFinished: () -> Void

    // MARK: - Initialization

    /// Initializes the AdManager with necessary dependencies.
    /// - Parameters:
    ///   - player: The AVPlayer playing video content
    ///   - viewController: The host view controller for ad UI
    ///   - adContainerView: The view to display ads in
    ///   - onAdFinished: Callback when ads complete or error out
    init(player: AVPlayer,
         viewController: UIViewController,
         adContainerView: UIView,
         onAdFinished: @escaping () -> Void) {
        self.player = player
        self.viewController = viewController
        self.adContainerView = adContainerView
        self.onAdFinished = onAdFinished
        super.init()
        setupIMA()  // Configure IMA SDK components
    }

    /// Configures IMASettings, adsLoader, and content playhead for AVPlayer
    private func setupIMA() {
        let settings = IMASettings()
        adsLoader = IMAAdsLoader(settings: settings)
        adsLoader.delegate = self
        contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: player)
    }

    // MARK: - Public Ad Request

    /// Requests ads from the given VMAP/VAST tag URL.
    /// - Parameter adTagUrl: The ad server URL including correlator parameter
    func requestAds(adTagUrl: String) {
        // Ensure view controller still exists
        guard let viewController = viewController else {
            print("Error: viewController is nil.")
            return
        }

        // Create ad display container with the target view and VC
        let adDisplayContainer = IMAAdDisplayContainer(
            adContainer: adContainerView,
            viewController: viewController,
            companionSlots: nil
        )

        // Build ads request with display container and content playhead
        let request = IMAAdsRequest(
            adTagUrl: adTagUrl,
            adDisplayContainer: adDisplayContainer,
            contentPlayhead: contentPlayhead,
            userContext: nil
        )

        // Trigger ad loading
        adsLoader.requestAds(with: request)
    }
}

// MARK: - IMAAdsLoaderDelegate

extension AdManager: IMAAdsLoaderDelegate {
    /// Called when ads have been successfully loaded.
    func adsLoader(_ loader: IMAAdsLoader, adsLoadedWith adsLoadedData: IMAAdsLoadedData) {
        adsManager = adsLoadedData.adsManager
        adsManager?.delegate = self

        // Debug: Print cue point information (pre-, mid-, post-roll)
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

        // Initialize adsManager with default rendering settings
        let adsRenderingSettings = IMAAdsRenderingSettings()
        adsManager?.initialize(with: adsRenderingSettings)
    }

    /// Called if ad loading fails; logs error and triggers content playback
    func adsLoader(_ loader: IMAAdsLoader, failedWith adErrorData: IMAAdLoadingErrorData) {
        print("Ad loading failed: \(adErrorData.adError.message ?? "Unknown error")")
        onAdFinished()  // Fallback to content playback
    }
}

// MARK: - IMAAdsManagerDelegate

extension AdManager: IMAAdsManagerDelegate {
    /// Handles various ad events (loaded, started, completed)
    func adsManager(_ adsManager: IMAAdsManager, didReceive event: IMAAdEvent) {
        print("Ad Event: \(event.type.rawValue)")

        switch event.type {
        case .LOADED:
            // Start playback as soon as ad(s) are loaded
            adsManager.start()

        case .ALL_ADS_COMPLETED:
            // Resume content only after the entire ad pod finishes
            onAdFinished()

        default:
            break  // Handle other events if needed
        }
    }

    /// Handles ad playback errors by destroying the manager and resuming content
    func adsManager(_ adsManager: IMAAdsManager, didReceive error: IMAAdError) {
        print("Ad playback error: \(error.message ?? "Unknown error")")
        adsManager.destroy()
        self.adsManager = nil
        onAdFinished()
    }

    /// Pauses content when ad requests a pause (pre- or mid-roll start)
    func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager) {
        print("🔴 Requesting content pause for ad")
        player.pause()
        player.rate = 0.0  // Enforce no playback
    }

    /// Resumes content playback when ad signals resume
    func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager) {
        player.play()
    }
}
