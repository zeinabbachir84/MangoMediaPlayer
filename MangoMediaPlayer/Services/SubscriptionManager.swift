//
//  SubscriptionManager.swift
//  MangoMediaPlayer
//
//  Created by Zeinab Bachir on 20/05/2025.
//

import KeychainAccess
import UIKit

class SubscriptionManager: ObservableObject {
    @Published var isSubscribed: Bool {
        didSet {
            keychain["isSubscribed"] = isSubscribed ? "true" : "false"
        }
    }

    private let keychain = Keychain(service: "com.yourapp.identifier")

    init() {
        self.isSubscribed = keychain["isSubscribed"] == "true"
    }
}
