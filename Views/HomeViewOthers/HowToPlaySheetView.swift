//
//  HowToPlaySheetView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/25/26.
//


import SwiftUI

// MARK: - Responsive Tutorial Layout
// Original gameplay instructions are preserved.

struct HowToPlaySheetView: View {

    @Environment(\.dismiss)
    private var dismiss

    // MARK: - Main Layout

    var body: some View {
        GeometryReader { geometry in

            let compact = geometry.size.height < 410

            ZStack {
                AppTheme.backgroundTan
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
                                    .fill(AppTheme.outline)
                                    .frame(height: 1)

                                Image(
                                    systemName: "swords"
                                )
                                .font(.system(size: 18))

                                Rectangle()
                                    .fill(AppTheme.outline)
                                    .frame(height: 1)
                            }
                            .padding(.horizontal, 16)
                        }

                        // MARK: - Story and Cards

                        VStack(
                            alignment: .leading,
                            spacing: compact ? 8 : 12
                        ) {
                            Text("The Story")
                                .font(
                                    .system(
                                        size: 19,
                                        weight: .bold,
                                        design: .serif
                                    )
                                )

                            Text(
                                "You are the healer of three dangerously reckless teammates. Survive their terrible decisions and defeat Bonk before two teammates turn into ghosts."
                            )
                            .font(
                                .system(
                                    size: compact ? 12 : 14
                                )
                            )
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )

                            Text("Your Cards")
                                .font(
                                    .system(
                                        size: 19,
                                        weight: .bold,
                                        design: .serif
                                    )
                                )

                            HStack(
                                alignment: .top,
                                spacing: 8
                            ) {
                                guideCard(
                                    "heal card",
                                    title: "Heal",
                                    note: "+1 HP"
                                )

                                guideCard(
                                    "reverse card",
                                    title: "Reverse",
                                    note: "Redirect damage"
                                )

                                guideCard(
                                    "nothing card",
                                    title: "Do Nothing",
                                    note: "No intervention"
                                )
                            }

                            Text("Your Team")
                                .font(
                                    .system(
                                        size: 19,
                                        weight: .bold,
                                        design: .serif
                                    )
                                )

                            HStack(
                                alignment: .top,
                                spacing: 8
                            ) {
                                guideCard(
                                    "vampire head",
                                    title: "Vampire",
                                    note: "Risky ally attacks"
                                )

                                guideCard(
                                    "knight head",
                                    title: "Knight",
                                    note: "Powerful but reckless"
                                )

                                guideCard(
                                    "boom head",
                                    title: "Dr. Boom Boom",
                                    note: "Unpredictable bombs"
                                )
                            }

                            Text(
                                "Tap a teammate to inspect their possible moves. Drag a healer card from your hand onto a living teammate, then start the encounter. Use the pause menu or the ? button to reopen this guide anytime."
                            )
                            .font(
                                .system(
                                    size: compact ? 12 : 14
                                )
                            )
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )
                        }
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )

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
                                    AppTheme.darkBrown,
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                    .foregroundStyle(AppTheme.darkBrown)
                    .padding(compact ? 14 : 20)
                    .background(
                        AppTheme.paper.opacity(0.58),
                        in: RoundedRectangle(cornerRadius: 22)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(
                                AppTheme.outline.opacity(0.85),
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
        .presentationBackground(AppTheme.backgroundTan)
    }

    private func guideCard(
        _ image: String,
        title: String,
        note: String
    ) -> some View {
        VStack(spacing: 4) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(height: 57)

            Text(title)
                .font(
                    .system(
                        size: 11,
                        weight: .bold
                    )
                )
                .lineLimit(2)

            Text(note)
                .font(.system(size: 10))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(6)
        .background(
            AppTheme.paper,
            in: RoundedRectangle(cornerRadius: 10)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppTheme.outline.opacity(0.55))
        }
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
                .fill(AppTheme.outline.opacity(0.7))
                .frame(width: 1)

            Text(text)
                .font(
                    .system(
                        size: compact ? 13 : 15
                    )
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
        .foregroundStyle(AppTheme.darkBrown)
        .padding(compact ? 10 : 15)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            AppTheme.paper,
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    AppTheme.outline.opacity(0.55),
                    lineWidth: 1
                )
        }
    }
}

