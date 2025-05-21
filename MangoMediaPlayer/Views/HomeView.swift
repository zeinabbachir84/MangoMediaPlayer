//
//  HomeView.swift
//  MangoMediaPlayer
//
//  Created by Zeinab Bachir on 20/05/2025.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var selectedVideoURL: URL? = nil

    private let verticalCarouselImages = ["v1", "v2", "v3", "v4", "v5"]
    private let horizontalCarouselImages = ["h1", "h2", "h3", "h4", "h5"]
    private let sampleVideoURL = URL(string: "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8")!

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 240/255, green: 240/255, blue: 240/255)
                    .ignoresSafeArea() // full screen light gray background
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Toggle subscription state
                        Toggle(isOn: $subscriptionManager.isSubscribed) {
                            Label("Subscribed", systemImage: subscriptionManager.isSubscribed ? "checkmark.circle.fill" : "xmark.circle")
                                .foregroundColor(subscriptionManager.isSubscribed ? .green : .red)
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
            .navigationDestination(item: $selectedVideoURL) { url in
                PlayerView(videoURL: url, isSubscribed: subscriptionManager.isSubscribed)
            }
        }
    }
}

// MARK: - Carousel Section View

struct CarouselSection: View {
    let title: String
    let images: [String]
    let imageSize: CGSize
    let onTap: () -> Void
    @State private var animateItems = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                        .opacity(animateItems ? 1 : 0)
                        .offset(x: animateItems ? 0 : 50)
                        .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.1), value: animateItems)
                    }
                }
                .padding(.horizontal)
            }
            .onAppear {
                animateItems = true
            }
        }
    }
}

// MARK: - Video Thumbnail Button

struct VideoThumbnailButton: View {
    let imageName: String
    let size: CGSize
    let onTap: () -> Void
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

                Image(systemName: "play.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.white)
                    .opacity(isPressed ? 1 : 0.5)
                    .scaleEffect(isPressed ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isPressed)
            }
        }
        .accessibilityLabel(Text("Play video from thumbnail"))
    }
}
