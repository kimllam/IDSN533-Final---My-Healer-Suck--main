import SwiftUI
import FirebaseAuth

struct RootView: View {

    @Environment(\.scenePhase)
    private var scenePhase

    @AppStorage("hasSeenOnboarding")
    private var hasSeenOnboarding = false

    @AppStorage("entryMode")
    private var entryMode = ""

    @State private var justFinishedOnboarding = false
    @State private var isAuthenticated = false
    @State private var isGuest = false

    @State private var authListenerHandle:
        AuthStateDidChangeListenerHandle?

    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingComicView(
                    onFinish: {
                        hasSeenOnboarding = true
                        justFinishedOnboarding = true
                        isGuest = false
                        entryMode = ""
                    }
                )
            } else if justFinishedOnboarding {
                NavigationStack {
                    AuthView(
                        mode: .logIn,
                        onAuthenticated: {
                            justFinishedOnboarding = false
                            finishAccountLogin()
                        },
                        onPlayAsGuest: {
                            justFinishedOnboarding = false
                            enterGuestMode()
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
                            finishAccountLogin()
                        },
                        onPlayAsGuest: {
                            enterGuestMode()
                        }
                    )
                }
            }
        }
        .animation(
            .easeInOut(duration: 0.25),
            value: justFinishedOnboarding
        )
        .animation(
            .easeInOut(duration: 0.25),
            value: isAuthenticated || isGuest
        )
        .onChange(
            of: scenePhase,
            initial: true
        ) { _, phase in
            AudioManager.shared.setApplicationActive(
                phase == .active
            )
        }
        .onAppear {
            AudioManager.shared.setApplicationActive(
                scenePhase == .active
            )

            updateEntryState()

            guard authListenerHandle == nil else {
                return
            }

            authListenerHandle = Auth.auth()
                .addStateDidChangeListener { _, user in
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

                        if entryMode == "account" {
                            entryMode = ""
                        }
                    }
                }
        }
        .onChange(of: entryMode) { _, _ in
            updateEntryState()
        }
        .onDisappear {
            if let handle = authListenerHandle {
                Auth.auth().removeStateDidChangeListener(handle)
                authListenerHandle = nil
            }
        }
    }

    // MARK: - Account Login

    private func finishAccountLogin() {
        guard Auth.auth().currentUser?.isEmailVerified == true else {
            return
        }

        entryMode = "account"
        isAuthenticated = true
        isGuest = false
    }

    // MARK: - Guest Login

    private func enterGuestMode() {
        entryMode = "guest"
        isGuest = true
        isAuthenticated = false
    }

    // MARK: - Restore Entry State

    private func updateEntryState() {
        if entryMode == "guest" {
            isGuest = true
            isAuthenticated = false
        } else if entryMode == "account",
                  Auth.auth().currentUser?.isEmailVerified == true {
            isAuthenticated = true
            isGuest = false
        } else {
            isAuthenticated = false
            isGuest = false
        }
    }
}
