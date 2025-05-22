//
//  HomeView.swift
//  MangoMediaPlayer
//
//  Created by Zeinab Bachir on 20/05/2025.
//

import SwiftUI

/// The main home screen of the app.
/// - Manages subscription state
/// - Displays two image carousels (vertical & horizontal)
/// - Launches the player when a thumbnail is tapped

struct HomeView: View {
    // SubscriptionManager persists whether user is subscribed (used to skip ads)
    @StateObject private var subscriptionManager = SubscriptionManager()
    // Holds the URL to play; non-nil triggers navigation to PlayerViewWrapper
    @State private var selectedVideoURL: URL? = nil
    
    private let verticalCarouselImages = ["v1", "v2", "v3", "v4", "v5"]
    private let horizontalCarouselImages = ["h1", "h2", "h3", "h4", "h5"]
    // Sample HLS video URL used for all thumbnails
    private let sampleVideoURL = URL(string: "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8")!
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color applied edge-to-edge
                Color.backgroundGray
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Toggle subscription state
                        // Simulates user subscription; toggles ad skipping
                        Toggle(isOn: $subscriptionManager.isSubscribed) {
                            Label("Subscribed", systemImage: subscriptionManager.isSubscribed ? "checkmark.circle.fill" : "xmark.circle")
                                .foregroundColor(subscriptionManager.isSubscribed ? .green : .red)
                            // Animate the icon color change
                                .animation(.easeInOut, value: subscriptionManager.isSubscribed)
                        }
                        .padding()
                        
                        // Vertical Carousel
                        CarouselSection(
                            title: "Vertical Image Carousel",
                            images: verticalCarouselImages,
                            imageSize: CGSize(width: 100, height: 150),
                            onTap: { selectedVideoURL = sampleVideoURL }
                        )
                        
                        // Horizontal Carousel
                        CarouselSection(
                            title: "Horizontal Image Carousel",
                            images: horizontalCarouselImages,
                            imageSize: CGSize(width: 150, height: 100),
                            onTap: { selectedVideoURL = sampleVideoURL }
                        )
                    }
                }
            }
            .navigationTitle("Mango")
            // Navigate to the player when a URL is selected
            .navigationDestination(item: $selectedVideoURL) { url in
                PlayerViewWrapper(videoURL: url, isSubscribed: subscriptionManager.isSubscribed)
            }
        }
    }
}

// MARK: - Carousel Section View

/// A reusable carousel section with animated thumbnails.
/// - `title`: displayed above the carousel
/// - `images`: array of asset names
/// - `imageSize`: dimensions for each thumbnail
/// - `onTap`: action when a thumbnail is tapped
///
struct CarouselSection: View {
    let title: String
    let images: [String]
    let imageSize: CGSize
    let onTap: () -> Void
    
    // Controls the entrance animation of thumbnails
    @State private var animateItems = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(images.indices, id: \.self) { index in
                        VideoThumbnailButton(
                            imageName: images[index],
                            size: imageSize,
                            onTap: onTap
                        )
                        // Fade & slide in each item with a stagger delay
                        .opacity(animateItems ? 1 : 0)
                        .offset(x: animateItems ? 0 : 50)
                        .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.1), value: animateItems)
                    }
                }
                .padding(.horizontal)
            }
            .onAppear {
                // Trigger animation once when view appears
                if !animateItems {
                    animateItems = true
                }
            }
        }
    }
}

// MARK: - Video Thumbnail Button

/// A single video thumbnail button with a bouncy tap effect.
/// - `imageName`: asset name for thumbnail
/// - `size`: width & height of the thumbnail
/// - `onTap`: action to launch the video player
///
struct VideoThumbnailButton: View {
    let imageName: String
    let size: CGSize
    let onTap: () -> Void
    
    // Whether the button is currently pressed (for animation)
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation { // adding bouncy scale effect on tap
                isPressed = true
            }
            onTap()
        }) {
            ZStack {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .cornerRadius(8)
                
                Color.black.opacity(0.3)
                    .cornerRadius(8)
                
                // Play icon
                Image(systemName: "play.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.white)
                // Bounce & fade effect when pressed
                    .opacity(isPressed ? 1 : 0.5)
                    .scaleEffect(isPressed ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isPressed)
            }
        }
        // Accessibility for VoiceOver
        .accessibilityLabel(Text("Play video from thumbnail"))
    }
}
