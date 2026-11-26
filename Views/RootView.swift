

import SwiftUI
import FirebaseAuth

struct RootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("entryMode") private var entryMode = ""

    @State private var justFinishedOnboarding = false
    @State private var isAuthenticated = false
    @State private var isGuest = false
    @State private var authListenerHandle: AuthStateDidChangeListenerHandle?

    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingComicView(onFinish: {
                    hasSeenOnboarding = true
                    justFinishedOnboarding = true
                    isGuest = false
                    entryMode = ""
                })
            } else if justFinishedOnboarding {
                NavigationStack {
                    AuthView(
                        mode: .logIn,
                        onAuthenticated: {
                            justFinishedOnboarding = false
                            if Auth.auth().currentUser?.isEmailVerified == true {
                                isAuthenticated = true
                                isGuest = false
                            }
                        },
                        onPlayAsGuest: {
                            justFinishedOnboarding = false
                            isGuest = true
                        }
                    )
                }
            } else if isAuthenticated || isGuest {
                NavigationStack {
                    HomeView(
                        isGuest: isGuest,
                        onExitGuest: {
                            isGuest = false
                            if entryMode == "guest" {
                                entryMode = ""
                            }
                        }
                    )
                }
            } else {
                NavigationStack {
                    AuthView(
                        mode: .logIn,
                        onAuthenticated: {
                            if Auth.auth().currentUser?.isEmailVerified == true {
                                isAuthenticated = true
                                isGuest = false
                            }
                        },
                        onPlayAsGuest: {
                            isGuest = true
                        }
                    )
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: justFinishedOnboarding)
        .animation(.easeInOut(duration: 0.25), value: isAuthenticated || isGuest)
        .onAppear {
            // Restore an explicitly selected guest session without mixing account data.
            if entryMode == "guest" {
                isGuest = true
                isAuthenticated = false
            }
            guard authListenerHandle == nil else { return }
            authListenerHandle = Auth.auth().addStateDidChangeListener { _, user in
                if entryMode == "guest" {
                    isAuthenticated = false
                    isGuest = true
                } else if let user, user.isEmailVerified {
                    entryMode = "account"
                    isAuthenticated = true
                    isGuest = false
                } else {
                    isAuthenticated = false
                    isGuest = false
                    if entryMode == "account" { entryMode = "" }
                }
            }
        }
        .onChange(of: entryMode) { _, newMode in
            if newMode == "guest" {
                isGuest = true
                isAuthenticated = false
            } else if newMode == "account",
                      Auth.auth().currentUser?.isEmailVerified == true {
                isAuthenticated = true
                isGuest = false
            } else if newMode.isEmpty {
                isAuthenticated = false
                isGuest = false
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

