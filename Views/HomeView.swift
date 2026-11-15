
//
//  HomeView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/11/26.
//  Added by Jingyi: Settings button on the home screen.
//  Updated by Jingyi: Account selection and unified tutorial layout.
//

import SwiftUI

struct HomeView: View {

    @EnvironmentObject var game: GameManager

    @State private var showHowToPlay = false
    @State private var showSettings = false

    // MARK: - Existing Colors

    private let lightTan = Color(
        red: 245 / 255,
        green: 215 / 255,
        blue: 180 / 255
    )

    private let darkBrown = Color(
        red: 0.35,
        green: 0.23,
        blue: 0.18
    )

    // MARK: - Main View

    var body: some View {
        GeometryReader { geometry in
            ZStack {

                // Full-screen landing artwork

                Image("landing")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .clipped()
                    .allowsHitTesting(false)

                // Existing home buttons

                VStack(spacing: 12) {

                    // MARK: - Play Button
                    // Updated by Jingyi: Open account selection
                    // before entering gameplay.

                    NavigationLink {
                        WelcomeView()
                    } label: {

                        Text("Play")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .frame(width: 210, height: 48)
                            .background(darkBrown)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 24)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(
                                        darkBrown,
                                        lineWidth: 2
                                    )
                            }
                            .shadow(
                                color: .black.opacity(0.25),
                                radius: 4,
                                y: 2
                            )
                    }
                    .buttonStyle(.plain)

                    // MARK: - How to Play Button
                    // Original button style retained.

                    Button {
                        showHowToPlay = true
                    } label: {

                        Text("How to Play")
                            .font(.headline.bold())
                            .foregroundColor(darkBrown)
                            .frame(width: 210, height: 42)
                            .background(lightTan)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 21)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 21)
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
                .position(
                    x: min(
                        max(geometry.size.width * 0.82, 116),
                        max(geometry.size.width - 116, 116)
                    ),
                    y: geometry.size.height * 0.63
                )
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )

            // MARK: - Home Settings
            // Added by Jingyi: Settings button only.

            .overlay(alignment: .topTrailing) {

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
                        .foregroundColor(darkBrown)
                        .frame(width: 46, height: 46)
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
                .padding(.top, 12)
                .padding(.trailing, 20)
            }
        }
        .background {
            Image("landing")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)

        // MARK: - Sheets

        .sheet(isPresented: $showHowToPlay) {
            HowToPlaySheetView()
        }

        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

// MARK: - How to Play
// Updated by Jingyi: Match the in-game tutorial layout.
// Original gameplay instructions are preserved.

struct HowToPlaySheetView: View {

    @Environment(\.dismiss)
    private var dismiss

    // MARK: - Colors

    private let backgroundTan = Color(
        red: 252 / 255,
        green: 220 / 255,
        blue: 187 / 255
    )

    private let paper = Color(
        red: 255 / 255,
        green: 243 / 255,
        blue: 228 / 255
    )

    private let brown = Color(
        red: 89 / 255,
        green: 59 / 255,
        blue: 46 / 255
    )

    private let outline = Color(
        red: 190 / 255,
        green: 151 / 255,
        blue: 119 / 255
    )

    // MARK: - Main Layout

    var body: some View {
        GeometryReader { geometry in

            ZStack {
                backgroundTan
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // MARK: - Title

                        VStack(spacing: 10) {

                            Text("How to Play")
                                .font(
                                    .system(
                                        size: 32,
                                        weight: .black,
                                        design: .serif
                                    )
                                )

                            HStack(spacing: 12) {

                                Rectangle()
                                    .fill(outline)
                                    .frame(height: 1)

                                Image(systemName: "swords")
                                    .font(.system(size: 18))

                                Rectangle()
                                    .fill(outline)
                                    .frame(height: 1)
                            }
                            .padding(.horizontal, 16)
                        }

                        // MARK: - Gameplay Rules
                        // Original English instructions preserved.

                        VStack(spacing: 12) {

                            ruleCard(
                                number: "01",
                                text: "Each idiot draws 2 possible moves and will always pick the most self-destructive one."
                            )

                            ruleCard(
                                number: "02",
                                text: "Drag Heal (+1 HP), Reverse, or Do Nothing onto each idiot before starting the encounter."
                            )

                            ruleCard(
                                number: "03",
                                text: "Use Reverse to redirect self-damage or friendly fire straight onto Bonk!"
                            )

                            ruleCard(
                                number: "04",
                                text: "Win by dropping Bonk to 0 HP. Lose if two idiots become ghosts."
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
                                .frame(height: 50)
                                .background(
                                    brown,
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                    .foregroundStyle(brown)
                    .padding(20)
                    .background(
                        paper.opacity(0.58),
                        in: RoundedRectangle(
                            cornerRadius: 22
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(
                                outline.opacity(0.85),
                                lineWidth: 1.2
                            )
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 24)
                    .frame(maxWidth: 520)
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

    // MARK: - Rule Cards
    // Updated by Jingyi: Individual numbered rule cards.

    private func ruleCard(
        number: String,
        text: String
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 12
        ) {

            Text(number)
                .font(
                    .system(
                        size: 17,
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
                .font(.system(size: 15))
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
        .padding(15)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            paper,
            in: RoundedRectangle(
                cornerRadius: 14
            )
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

