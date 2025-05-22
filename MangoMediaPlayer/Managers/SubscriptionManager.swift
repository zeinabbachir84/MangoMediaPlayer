//
//  SubscriptionManager.swift
//  MangoMediaPlayer
//
//  Created by Zeinab Bachir on 20/05/2025.
//

import KeychainAccess
import UIKit

/// Manages the user's subscription state, persisting it securely in the Keychain.
/// Observers can react to changes via the `isSubscribed` published property.
class SubscriptionManager: ObservableObject {
    // MARK: - Published Properties

    /// Indicates whether the user is currently subscribed.
    /// Writing to this property also updates the Keychain.
    @Published var isSubscribed: Bool {
        didSet {
            // Persist subscription state as a string in Keychain
            keychain[Self.keychainKey] = isSubscribed ? "true" : "false"
        }
    }

    // MARK: - Private Properties

    /// Keychain instance scoped to this app's bundle identifier
    private let keychain = Keychain(service: "com.MangoMediaPlayer.app")
    /// Key used to store subscription flag in Keychain
    private static let keychainKey = "isSubscribed"

    // MARK: - Initialization

    /// Initializes the subscription manager by reading the saved state from Keychain.
    /// If no value exists, defaults to `false` (not subscribed).
    init() {
        // Read stored value; default to false if not present
        let storedValue = keychain[Self.keychainKey]
        self.isSubscribed = (storedValue == "true")
    }
}
