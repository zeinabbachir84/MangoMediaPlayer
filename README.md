# MangoMediaPlayer

A feature-rich iOS media player application built with Swift and AVKit. It supports HLS video playback, Google IMA ads integration (pre-roll, mid-roll, post-roll), seamless ad-to-content transitions, and state persistence using Keychain.

## 🚀 Features

This project is divided into several core components:

### 🏠 Home Page

- A modern, scrollable home screen with **two content carousels**:
  - One carousel displays **vertical images**
  - The other carousel displays **horizontal images**
- Optimized for smooth scrolling and responsive layout

### 🎥 HLS Media Playback

- Plays **HLS (HTTP Live Streaming)** video streams using `AVPlayer`
- Custom-designed **player controls**:
  - Play/pause toggle
  - Seek bar
  - Fullscreen toggle
  - Optional overlays

### 📺 Google IMA Ads Integration

- Seamless integration of **Google Interactive Media Ads (IMA)** SDK
- Supports:
  - **Pre-roll** ads (play before content)
  - **Mid-roll** ads (inserted during playback)
  - **Post-roll** ads (play after content ends)
- After a **mid-roll ad**, the main video **resumes exactly where it left off**
- Custom ad container with support for skippable and non-skippable formats

### 🔐 User Subscription State

- Saves whether a user is **subscribed or not** using **Keychain** for secure and persistent storage
- Subscription state is read during app launch to personalize user experience

## 📱 Requirements

- iOS 17.6+
- Xcode 16+
- Swift 5.9+
- Google IMA SDK

## 🧩 Dependencies

- [Google IMA SDK](https://github.com/googleads/googleads-ima-ios) (via Swift Package Manager)
- AVFoundation (built-in)
- UIKit (built-in)
- SwiftKeychainWrapper (optional helper for Keychain access)
  
## 🛠 Setup Instructions

1. Clone the repo:
   ```bash
   git clone https://github.com/zeinabbachir84/MangoMediaPlayer.git
   cd MangoMediaPlayer

2. Open the project in Xcode:
open MangoMediaPlayer.xcodeproj

3. Build and run the app on an iOS simulator or device.
