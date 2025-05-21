//
//  PlayerView.swift
//  MangoMediaPlayer
//
//  Created by Zeinab Bachir on 20/05/2025.
//
import SwiftUI
import AVKit

struct PlayerView: View, Identifiable {
    let id = UUID()
    let videoURL: URL
    let isSubscribed: Bool

    var body: some View {
        VStack {
            if isSubscribed {
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .onAppear {
                        AVPlayer(url: videoURL).play()
                    }
            } else {
                Text("Ads will play here before the content (IMA Integration pending)")
                // Placeholder for IMA Ad integration
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .onAppear {
                        AVPlayer(url: videoURL).play()
                    }
            }
        }
        .navigationTitle("Now Playing")
        .navigationBarTitleDisplayMode(.inline)
    }
}

