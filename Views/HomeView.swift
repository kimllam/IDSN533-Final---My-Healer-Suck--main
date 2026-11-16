//
//  HomeView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/11/26.
//  Added by Jingyi: Settings button on the home screen.
//  Updated by Jingyi: Account selection and unified tutorial layout.
//  Updated by Jingyi: Align landscape controls with the artwork title.
//

import SwiftUI

struct HomeView: View {

    @EnvironmentObject var game: GameManager

    @State private var showHowToPlay = false
    @State private var showSettings = false

    // MARK: - Colors

    private let lightTan = Color(
        red: 245.0 / 255,
        green: 215.0 / 255,
        blue: 180.0 / 255
    )

    private let darkBrown = Color(
        red: 0.35,
        green: 0.23,
        blue: 0.18
    )

    private let backgroundTan = Color(
        red: 252.0 / 255,
        green: 220.0 / 255,
        blue: 187.0 / 255
    )

    // MARK: - Main View
    // Updated by Jingyi:
    // Artwork and controls now share ONE full-screen
    // coordinate space, so buttons line up with the
    // title painted in the artwork.

    var body: some View {
        GeometryReader { screen in

            let size = screen.size
            let insets = screen.safeAreaInsets
            let isPortrait = size.width < size.height

            ZStack {

                // MARK: - Full-Screen Artwork

                Image("landing")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: size.width,
                        height: size.height
                    )
                    .clipped()
                    .allowsHitTesting(false)

                // MARK: - Controls

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
            backgroundTan
                .ignoresSafeArea()
        }
        .toolbar(
            .hidden,
            for: .navigationBar
        )

        // MARK: - Sheets

        .sheet(isPresented: $showHowToPlay) {
            HowToPlaySheetView()
        }

        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - Portrait Controls
    // Settings at the upper-right (inside safe area).
    // Both actions sit above the home indicator.

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

            // MARK: - Portrait Settings

            VStack {
                HStack {
                    Spacer(minLength: 0)

                    settingsButton
                }
                .padding(.trailing, 16)
                .padding(.top, 8)

                Spacer(minLength: 0)
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
    // Updated by Jingyi:
    // - Positioned in full-screen coordinates, the same
    //   space the artwork uses.
    // - Centered under the painted title (~80% of width).
    // - Clamped so it never enters the right safe area
    //   and never drifts left onto the characters.
    // - Vertically placed between the tagline and the
    //   bottom caption.

    private func landscapeControls(
        screen: CGSize,
        insets: EdgeInsets
    ) -> some View {

        let compact = screen.height < 400
        let gap: CGFloat = compact ? 10 : 12
        let settingsSize: CGFloat = 46
        let playHeight: CGFloat = 52
        let secondaryHeight: CGFloat = 46

        // Panel width roughly matches the title width.

        let panelWidth = min(
            300,
            max(230, screen.width * 0.27)
        )

        let groupHeight =
            playHeight + gap + secondaryHeight

        // MARK: Horizontal position

        // Center of the "My Healer Sucks!" title in the artwork.
        let titleCenterX = screen.width * 0.80

        // Right edge must stay inside the safe area.
        let maxCenterX =
            screen.width
            - insets.trailing
            - 12
            - panelWidth / 2

        // Left edge must stay clear of the illustration.
        let minCenterX =
            screen.width * 0.60
            + panelWidth / 2

        let centerX = max(
            minCenterX,
            min(titleCenterX, maxCenterX)
        )

        // MARK: Vertical position

        // Between the tagline (~42%) and the caption (~90%).
        let preferredCenterY = screen.height * 0.64

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

            // MARK: - Main Action

            playButton

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
        }
        .frame(width: panelWidth)
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
    // Added by Jingyi:
    // Keep the original circular design.

    private var settingsButton: some View {
        Button {
            showSettings = true
        } label: {

            Image(
                systemName: "gearshape.fill"
            )
            .font(
                .system(
                    size: 21,
                    weight: .semibold
                )
            )
            .foregroundStyle(darkBrown)
            .frame(
                width: 46,
                height: 46
            )
            .background(
                lightTan,
                in: Circle()
            )
            .overlay {
                Circle()
                    .stroke(
                        darkBrown,
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
    // Preserve account selection before gameplay.

    private var playButton: some View {
        NavigationLink {
            WelcomeView()
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
                    darkBrown,
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .stroke(
                            darkBrown,
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
    // Original functionality retained.

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
                .foregroundStyle(darkBrown)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    lightTan,
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .stroke(
                            darkBrown,
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

// MARK: - How to Play
// Updated by Jingyi: Responsive tutorial layout.
// Original gameplay instructions are preserved.

struct HowToPlaySheetView: View {

    @Environment(\.dismiss)
    private var dismiss

    // MARK: - Colors

    private let backgroundTan = Color(
        red: 252.0 / 255,
        green: 220.0 / 255,
        blue: 187.0 / 255
    )

    private let paper = Color(
        red: 255.0 / 255,
        green: 243.0 / 255,
        blue: 228.0 / 255
    )

    private let brown = Color(
        red: 89.0 / 255,
        green: 59.0 / 255,
        blue: 46.0 / 255
    )

    private let outline = Color(
        red: 190.0 / 255,
        green: 151.0 / 255,
        blue: 119.0 / 255
    )

    // MARK: - Main Layout

    var body: some View {
        GeometryReader { geometry in

            let compact = geometry.size.height < 410

            ZStack {
                backgroundTan
                    .ignoresSafeArea()

                ScrollView(
                    .vertical,
                    showsIndicators: false
                ) {
                    VStack(
                        spacing: compact ? 12 : 20
                    ) {

                        // MARK: - Tutorial Header

                        VStack(spacing: 10) {

                            Text("How to Play")
                                .font(
                                    .system(
                                        size: compact ? 26 : 32,
                                        weight: .black,
                                        design: .serif
                                    )
                                )

                            HStack(spacing: 12) {

                                Rectangle()
                                    .fill(outline)
                                    .frame(height: 1)

                                Image(
                                    systemName: "swords"
                                )
                                .font(.system(size: 18))

                                Rectangle()
                                    .fill(outline)
                                    .frame(height: 1)
                            }
                            .padding(.horizontal, 16)
                        }

                        // MARK: - Gameplay Rules

                        VStack(
                            spacing: compact ? 8 : 12
                        ) {
                            ruleCard(
                                number: "01",
                                text: "Each idiot draws 2 possible moves and will always pick the most self-destructive one.",
                                compact: compact
                            )

                            ruleCard(
                                number: "02",
                                text: "Drag Heal (+1 HP), Reverse, or Do Nothing onto each idiot before starting the encounter.",
                                compact: compact
                            )

                            ruleCard(
                                number: "03",
                                text: "Use Reverse to redirect self-damage or friendly fire straight onto Bonk!",
                                compact: compact
                            )

                            ruleCard(
                                number: "04",
                                text: "Win by dropping Bonk to 0 HP. Lose if two idiots become ghosts.",
                                compact: compact
                            )
                        }

                        // MARK: - Close Button

                        Button {
                            dismiss()
                        } label: {
                            Text("Got It")
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(
                                    height: compact ? 42 : 50
                                )
                                .background(
                                    brown,
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                    .foregroundStyle(brown)
                    .padding(compact ? 14 : 20)
                    .background(
                        paper.opacity(0.58),
                        in: RoundedRectangle(cornerRadius: 22)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(
                                outline.opacity(0.85),
                                lineWidth: 1.2
                            )
                    }
                    .frame(maxWidth: 520)
                    .padding(.horizontal, 18)
                    .padding(
                        .vertical,
                        compact ? 12 : 24
                    )
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height,
                        alignment: .center
                    )
                }
                .scrollIndicators(.hidden)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(backgroundTan)
    }

    // MARK: - Rule Card

    private func ruleCard(
        number: String,
        text: String,
        compact: Bool
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 12
        ) {

            Text(number)
                .font(
                    .system(
                        size: compact ? 14 : 17,
                        weight: .bold,
                        design: .serif
                    )
                )
                .frame(
                    width: 28,
                    alignment: .leading
                )

            Rectangle()
                .fill(outline.opacity(0.7))
                .frame(width: 1)

            Text(text)
                .font(
                    .system(size: compact ? 13 : 15)
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
        }
        .foregroundStyle(brown)
        .padding(compact ? 10 : 15)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            paper,
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    outline.opacity(0.55),
                    lineWidth: 1
                )
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HomeView()
    }
    .environmentObject(GameManager())
}
