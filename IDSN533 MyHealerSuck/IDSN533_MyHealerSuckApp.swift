
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

// MARK: - Landscape Orientation

@MainActor
enum LandscapeOrientation {
    static func request() {
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            guard scene.activationState == .foregroundActive ||
                  scene.activationState == .foregroundInactive else { continue }

            scene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            scene.requestGeometryUpdate(
                .iOS(interfaceOrientations: .landscape)
            ) { error in
                // Rotation is controlled by iOS and may be deferred in the Simulator.
                print("Landscape orientation request: \(error.localizedDescription)")
            }
        }
    }
}

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

    // Keep all app screens in landscape, including onboarding.
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        .landscape
    }
}

// MARK: - Root Navigation

@MainActor
final class AppRouteState: ObservableObject {
    @Published private(set) var rootID = UUID()
    @Published private(set) var showingAccountSelection = false

    func returnToLaunchScreen() {
        showingAccountSelection = false
        rootID = UUID()
    }

    func returnToAccountSelection() {
        showingAccountSelection = true
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
                RootView()
            }
        }
    }



