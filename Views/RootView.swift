//
//  RootView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/25/26.
//

import SwiftUI
import FirebaseAuth

struct RootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = true

    @State private var isAuthenticated = false
    @State private var isGuest = false
    @State private var authListenerHandle: AuthStateDidChangeListenerHandle?

    var body: some View {
        Group {
            // TODO: Uncomment when OnboardingComicView is built
            // if !hasSeenOnboarding {
            //     OnboardingComicView(onFinish: { hasSeenOnboarding = true })
            // } else
            if isAuthenticated || isGuest {
                NavigationStack {
                    HomeView(
                        isGuest: isGuest,
                        onExitGuest: {
                            isGuest = false
                        }
                    )
                }
            } else {
                AuthView(
                    onContinueAsGuest: {
                        isGuest = true
                    }
                )
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isAuthenticated || isGuest)
        .onAppear {
            guard authListenerHandle == nil else { return }
            authListenerHandle = Auth.auth().addStateDidChangeListener { _, user in
                isAuthenticated = (user != nil)
                if isAuthenticated {
                    isGuest = false
                }
            }
        }
        .onDisappear {
            if let handle = authListenerHandle {
                Auth.auth().removeStateDidChangeListener(handle)
                authListenerHandle = nil
            }
        }
    }
}
