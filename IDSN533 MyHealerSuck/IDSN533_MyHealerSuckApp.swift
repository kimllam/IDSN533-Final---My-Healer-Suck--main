
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

// MARK: - Root Navigation

@MainActor
final class AppRouteState: ObservableObject {
    @Published private(set) var rootID = UUID()

    func returnToLaunchScreen() {
        rootID = UUID()
    }
}

// MARK: - Main App

@main
struct MyHealerSucksApp: App {

    @Environment(\.scenePhase)
    private var scenePhase

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    private var delegate

    @StateObject private var game = GameManager()
    @StateObject private var appRoute = AppRouteState()

    @StateObject private var authManager: AuthManager

    // MARK: - Initialization

    init() {
        // Configure Firebase before creating AuthManager.
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
            

            // Shared game state
            .id(appRoute.rootID)
            .environmentObject(appRoute)
            .environmentObject(game)

            // Shared authentication state
            .environmentObject(authManager)
            .onChange(
                of: scenePhase,
                initial: true
            ) { _, phase in
                AudioManager.shared.setApplicationActive(
                    phase == .active
                )
            }
        }
    }
}

