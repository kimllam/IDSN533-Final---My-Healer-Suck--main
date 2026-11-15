
//
//  IDSN533_MyHealerSuckApp.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/11/26.
//  Updated by Jingyi: Firebase authentication integration.
//

import SwiftUI
import FirebaseCore

// MARK: - Firebase App Delegate
// Added by Jingyi: Configure Firebase during app launch.

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

@main
struct MyHealerSucksApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    private var delegate

    // Original game state retained.
    @StateObject private var game = GameManager()

    // Added by Jingyi: Shared authentication state.
    @StateObject private var authManager: AuthManager

    init() {

        // Ensure Firebase is ready before AuthManager.
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        _authManager = StateObject(
            wrappedValue: AuthManager()
        )
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
            .environmentObject(game)
            .environmentObject(authManager)
        }
    }
}

