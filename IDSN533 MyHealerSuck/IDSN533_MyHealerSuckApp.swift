
//
//  IDSN533_MyHealerSuckApp.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/11/26.
//  Updated by Jingyi: Firebase authentication and navigation.
//

import SwiftUI
import Combine
import FirebaseCore
import UIKit

// MARK: - Firebase App Delegate

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        return true
    }
}

// MARK: - Game Navigation

// Resets the navigation stack to the game's HomeView.
// This allows Return Home to work from different entry paths.

final class GameNavigation: ObservableObject {

    @Published private(set) var homeResetID = UUID()

    func returnToGameHome() {
        homeResetID = UUID()
    }
}

// MARK: - Main App

@main
struct MyHealerSucksApp: App {

    // MARK: - App Delegate

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    private var delegate

    // MARK: - Shared Game State

    @StateObject private var game = GameManager()

    // MARK: - Navigation State

    @StateObject private var navigation = GameNavigation()

    // MARK: - Authentication State

    @StateObject private var authManager: AuthManager

    // MARK: - Initialization

    init() {

        // Configure Firebase before initializing AuthManager.

        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        _authManager = StateObject(
            wrappedValue: AuthManager()
        )
    }

    // MARK: - Main Window

    var body: some Scene {

        WindowGroup {

            NavigationStack {

                HomeView()

            }
            .id(navigation.homeResetID)

            // Shared game state
            .environmentObject(game)

            // Shared authentication state
            .environmentObject(authManager)

            // Shared navigation state
            .environmentObject(navigation)
        }
    }
}

