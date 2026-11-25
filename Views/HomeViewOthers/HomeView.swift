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


    // MARK: - Main View
    // Artwork and controls share one coordinate space.

    var body: some View {
        GeometryReader { screen in

            let size = screen.size
            let insets = screen.safeAreaInsets
            let isPortrait = size.width < size.height

            ZStack {
                //home image
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

                // Top-Left account button
                VStack {
                    HStack {
                        accountButton
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.top, insets.top + 8)
                .padding(.leading, insets.leading + 16)
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
    }

    // MARK: - Title Logo

    private var titleLogo: some View {
        Image("GameTitle")
            .resizable()
            .scaledToFit()
            .allowsHitTesting(false)
            .accessibilityLabel("My Healer Sucks!")
    }

    // MARK: - Account Button

    private var accountButton: some View {
        Button {
            if isGuest {
                onExitGuest()
            } else {
                try? Auth.auth().signOut()
            }
        } label: {
            Text(isGuest ? "Sign In" : "Sign Out")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppTheme.darkBrown)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(AppTheme.lightTan.opacity(0.9))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(AppTheme.darkBrown.opacity(0.4), lineWidth: 1)
                )
        }
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
                    howToPlayButton
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
        let settingsSize: CGFloat = 46
        let playHeight: CGFloat = 52
        let secondaryHeight: CGFloat = 46
        let titleMaxHeight: CGFloat = compact ? 110 : 140

        // Buttons stay compact while the title
        // spans the right-side parchment space.

        let panelWidth = min(
            290,
            max(220, screen.width * 0.25)
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

                settingsButton
                    .frame(
                        width: settingsSize,
                        height: settingsSize
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
    // Restore verified Firebase accounts.
    // Keep the original button appearance.

    private var playButton: some View {
        NavigationLink {
            if auth.isLoggedIn && auth.isEmailVerified {
                GameBoardView()
                    .navigationBarBackButtonHidden(true)
                    .toolbar(
                        .hidden,
                        for: .navigationBar
                    )
                    .onAppear {
                        entryMode = "account"
                        GameRecordStore.shared
                            .refreshForCurrentAccount()
                    }
            } else {
                WelcomeView()
            }
        } label: {

            Text("Play")
                .font(
                    .system(
                        size: 20,
                        weight: .bold
                    )
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
        .disabled(!auth.hasCheckedAuthState)
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

// MARK: - Preview

#Preview {
    NavigationStack {
        HomeView()
    }
    .environmentObject(GameManager())
    .environmentObject(AuthManager())
}
