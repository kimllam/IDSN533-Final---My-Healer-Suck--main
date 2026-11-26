//  HomeView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/11/26.

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    var isGuest: Bool = false
    var onExitGuest: () -> Void = {}

    init(isGuest: Bool = false, onExitGuest: @escaping () -> Void = {}) {
        self.isGuest = isGuest
        self.onExitGuest = onExitGuest
    }

    @EnvironmentObject var game: GameManager
    @EnvironmentObject private var auth: AuthManager
    @AppStorage("entryMode") private var entryMode = ""

    @State private var showHowToPlay = false
    @State private var showSettings = false
    @State private var showProfilePopup = false

    // MARK: - Main View
    // Artwork and controls share one coordinate space.

    var body: some View {
        GeometryReader { screen in

            let size = screen.size
            let insets = screen.safeAreaInsets
            let isPortrait = size.width < size.height

            ZStack {
                // home image
                Image("landing")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: size.width,
                        height: size.height
                    )
                    .clipped()
                    .allowsHitTesting(false)

                // controls
                if isPortrait {
                    portraitControls(
                        screen: size,
                        insets: insets
                    )
                } else {
                    landscapeControls(
                        screen: size,
                        insets: insets
                    )
                }
            }
            .frame(
                width: size.width,
                height: size.height
            )
        }
        .ignoresSafeArea()
        .background {
            AppTheme.backgroundTan
                .ignoresSafeArea()
        }
        .toolbar(
            .hidden,
            for: .navigationBar
        )

        // MARK: - Refresh Account Verification

        .task(id: auth.userID) {
            // Restore the current Firebase user without a password.
            if auth.isLoggedIn && !auth.isEmailVerified {
                _ = try? await auth.checkEmailVerification()
            }
        }

        // MARK: - Sheets

        .sheet(isPresented: $showHowToPlay) {
            HowToPlaySheetView()
        }

        .sheet(isPresented: $showSettings) {
            SettingsView()
        }

        .sheet(isPresented: $showProfilePopup) {
            PlayerProfileView()
                .environmentObject(auth)
        }
    }

    // MARK: - Title Logo

    private var titleLogo: some View {
        Image("GameTitle")
            .resizable()
            .scaledToFit()
            .allowsHitTesting(false)
            .accessibilityLabel("My Healer Sucks!")
    }

    // MARK: - Portrait Controls

    private func portraitControls(
        screen: CGSize,
        insets: EdgeInsets
    ) -> some View {

        let safeWidth = max(
            0,
            screen.width - insets.leading - insets.trailing
        )

        let safeHeight = max(
            0,
            screen.height - insets.top - insets.bottom
        )

        let compact = safeHeight < 650

        let buttonWidth = max(
            0,
            min(340, safeWidth - 48)
        )

        return ZStack {

            // MARK: - Portrait Settings & Large Title

            VStack(spacing: compact ? 8 : 14) {
                HStack {
                    Spacer(minLength: 0)
                    settingsButton
                }
                .padding(.trailing, 16)
                .padding(.top, 8)

                titleLogo
                    .frame(
                        maxWidth: safeWidth * 0.92,
                        maxHeight: compact ? 110 : 150
                    )
                    .padding(.horizontal, 12)

                Spacer(minLength: 0)
            }

            // MARK: - Portrait Action Buttons

            VStack(spacing: 0) {

                Spacer(minLength: 0)

                VStack(
                    spacing: compact ? 10 : 14
                ) {
                    playButton

                    HStack(spacing: 12) {
                        howToPlayButton
                            .frame(maxWidth: .infinity)

                        profileButton
                            .frame(width: 46, height: 46)
                    }
                }
                .frame(width: buttonWidth)
                .padding(
                    .bottom,
                    compact ? 16 : 28
                )
            }
        }
        .frame(
            width: safeWidth,
            height: safeHeight
        )
        .position(
            x: insets.leading + safeWidth / 2,
            y: insets.top + safeHeight / 2
        )
    }

    // MARK: - Landscape Controls

    private func landscapeControls(
        screen: CGSize,
        insets: EdgeInsets
    ) -> some View {

        let compact = screen.height < 400
        let gap: CGFloat = compact ? 10 : 12
        let iconButtonSize: CGFloat = 46
        let playHeight: CGFloat = 52
        let secondaryHeight: CGFloat = 46
        let titleMaxHeight: CGFloat = compact ? 110 : 140

        // Buttons stay compact while the title
        // spans the right-side parchment space.

        let panelWidth = min(
            310,
            max(240, screen.width * 0.28)
        )

        let rightZoneStart = screen.width * 0.64999
        let rightZoneEnd = screen.width - insets.trailing - 12

        let availableTitleWidth = max(
            panelWidth,
            rightZoneEnd - rightZoneStart
        )

        let titleWidth = min(500, availableTitleWidth)

        let groupHeight =
            titleMaxHeight + gap + playHeight + gap + secondaryHeight

        // MARK: - Horizontal Position

        let preferredCenterX = screen.width * 0.78
        let maxCenterX = rightZoneEnd - titleWidth / 2
        let minCenterX = rightZoneStart + titleWidth / 2

        let centerX = max(
            minCenterX,
            min(preferredCenterX, maxCenterX)
        )

        // MARK: - Vertical Position

        let preferredCenterY = screen.height * 0.45

        let maxCenterY =
            screen.height
            - insets.bottom
            - 12
            - groupHeight / 2

        let centerY = min(
            preferredCenterY,
            maxCenterY
        )

        return VStack(spacing: gap) {

            // MARK: - Oversized Title PNG

            titleLogo
                .frame(
                    width: titleWidth,
                    height: titleMaxHeight
                )
                .padding(.bottom, compact ? 2 : 6)

            // MARK: - Main Action

            playButton
                .frame(width: panelWidth)

            // MARK: - Secondary Actions

            HStack(spacing: gap) {

                howToPlayButton
                    .frame(maxWidth: .infinity)

                profileButton
                    .frame(
                        width: iconButtonSize,
                        height: iconButtonSize
                    )

                settingsButton
                    .frame(
                        width: iconButtonSize,
                        height: iconButtonSize
                    )
            }
            .frame(width: panelWidth)
        }
        .position(
            x: centerX,
            y: centerY
        )
        .frame(
            width: screen.width,
            height: screen.height
        )
    }

    // MARK: - Profile Button

    private var profileButton: some View {
        Button {
            showProfilePopup = true
        } label: {
            Image(systemName: "person.fill")
                .font(
                    .system(
                        size: 20,
                        weight: .semibold
                    )
                )
                .foregroundStyle(AppTheme.darkBrown)
                .frame(
                    width: 46,
                    height: 46
                )
                .background(
                    AppTheme.lightTan,
                    in: Circle()
                )
                .overlay {
                    Circle()
                        .stroke(
                            AppTheme.darkBrown,
                            lineWidth: 2
                        )
                }
                .shadow(
                    color: .black.opacity(0.18),
                    radius: 3,
                    y: 2
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Player Profile")
    }

    // MARK: - Settings Button

    private var settingsButton: some View {
        Button {
            showSettings = true
        } label: {

            Image(systemName: "gearshape.fill")
                .font(
                    .system(
                        size: 21,
                        weight: .semibold
                    )
                )
                .foregroundStyle(AppTheme.darkBrown)
                .frame(
                    width: 46,
                    height: 46
                )
                .background(
                    AppTheme.lightTan,
                    in: Circle()
                )
                .overlay {
                    Circle()
                        .stroke(
                            AppTheme.darkBrown,
                            lineWidth: 2
                        )
                }
                .shadow(
                    color: .black.opacity(0.18),
                    radius: 3,
                    y: 2
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Settings")
    }

    // MARK: - Play Button

    private var playButton: some View {
        NavigationLink {
            GameBoardView()
        } label: {
            Text("Start Game")
                .font(
                    .system(size: 20, weight: .bold)
                )
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    AppTheme.darkBrown,
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .stroke(
                            AppTheme.darkBrown,
                            lineWidth: 2
                        )
                }
                .shadow(
                    color: .black.opacity(0.25),
                    radius: 5,
                    y: 2
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - How to Play Button

    private var howToPlayButton: some View {
        Button {
            showHowToPlay = true
        } label: {

            Text("How to Play")
                .font(
                    .system(
                        size: 18,
                        weight: .bold
                    )
                )
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .foregroundStyle(AppTheme.darkBrown)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    AppTheme.lightTan,
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .stroke(
                            AppTheme.darkBrown,
                            lineWidth: 2
                        )
                }
                .shadow(
                    color: .black.opacity(0.15),
                    radius: 3,
                    y: 2
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Player Profile Pop-Up

private struct PlayerProfilePopupView: View {
    let isGuest: Bool
    let onExitGuest: () -> Void
    let onSignOut: () -> Void

    @EnvironmentObject private var auth: AuthManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Player Profile")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.darkBrown)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppTheme.darkBrown.opacity(0.7))
                }
                .buttonStyle(.plain)
            }

            Divider()

            if auth.isLoggedIn && !isGuest {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Signed In")
                        .font(.headline)
                        .foregroundStyle(AppTheme.darkBrown)

                    if let email = Auth.auth().currentUser?.email, !email.isEmpty {
                        Text(email)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.darkBrown.opacity(0.8))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                Button("Sign Out", action: onSignOut)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(AppTheme.darkBrown, in: Capsule())
                    .buttonStyle(.plain)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Guest Player")
                        .font(.headline)
                        .foregroundStyle(AppTheme.darkBrown)

                    Text("Playing as a guest.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.darkBrown.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                Button("Sign In", action: onExitGuest)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(AppTheme.darkBrown, in: Capsule())
                    .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.backgroundTan.ignoresSafeArea())
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HomeView()
    }
    .environmentObject(GameManager())
    .environmentObject(AuthManager())
}
