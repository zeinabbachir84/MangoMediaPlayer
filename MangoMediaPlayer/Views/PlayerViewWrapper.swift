//
//  PlayerViewWrapper.swift
//  MangoMediaPlayer
//
//  Created by Zeinab Bachir on 21/05/2025.
//

import SwiftUI

struct PlayerViewWrapper: UIViewControllerRepresentable {
    let videoURL: URL
    let isSubscribed: Bool

    func makeUIViewController(context: Context) -> PlayerViewController {
        return PlayerViewController(videoURL: videoURL, isSubscribed: isSubscribed)
    }

    func updateUIViewController(_ uiViewController: PlayerViewController, context: Context) {
        // No update needed
    }
}
