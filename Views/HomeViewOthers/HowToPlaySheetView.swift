//
//  HowToPlaySheetView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/25/26.
//

import SwiftUI

struct HowToPlaySheetView: View {

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AppTheme.backgroundTan
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 22) {

                    // MARK: - Rulebook Header

                    VStack(spacing: 10) {
                        Text("The Rulebook")
                            .font(.system(size: 32, weight: .black, design: .serif))

                        HStack(spacing: 12) {
                            Rectangle()
                                .fill(AppTheme.outline)
                                .frame(height: 1)

                            Image(systemName: "swords")
                                .font(.system(size: 18))

                            Rectangle()
                                .fill(AppTheme.outline)
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 24)
                    }

                    // MARK: - The Story

                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle("The Story")

                        Text(
                            "There’s only one way out but Bonk is standing in the way. The guild believes they must defeat him to escape. There’s just one problem..."
                        )
                        .font(.system(size: 14))
                        .fixedSize(horizontal: false, vertical: true)

                        Text("All of Your Teammates Have a Death Wish.")
                            .font(.system(size: 16, weight: .bold, design: .serif))
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(
                                AppTheme.paper,
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppTheme.outline.opacity(0.55), lineWidth: 1)
                            }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // MARK: - The Healer (player)

                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("You, the Healer")

                        // Healer Image + Intro
                        HStack(alignment: .center, spacing: 16) {
                            Image("healer")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 84, height: 84)
                                .padding(8)
                                .background(
                                    AppTheme.paper,
                                    in: RoundedRectangle(cornerRadius: 14)
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(AppTheme.outline.opacity(0.55), lineWidth: 1)
                                }

                            Text(
                                "You’re stuck keeping three reckless teammates alive. In order to defeat Bonk, you must keep 2 idiots alive. If 2 dies, you lose!"
                            )
                            .font(.system(size: 14))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Larger Vertically Aligned Healer Cards
                        HStack(alignment: .top, spacing: 4) {
                            healerActionCard(
                                image: "heal card",
                                title: "Heal",
                                description: "+1HP"
                            )

                            healerActionCard(
                                image: "reverse card",
                                title: "Reverse",
                                description: "Flip the actions \n heal ↔ harm"
                            )

                            healerActionCard(
                                image: "nothing card",
                                title: "Do Nothing",
                                description: "Sit there and watch them fail"
                            )
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // MARK: - The Characters

                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("The Characters")

                        HStack(alignment: .top, spacing: 12) {
                            // Left Stack: Three Idiots
                            VStack(spacing: 10) {
                                characterRowCard(
                                    image: "vampire head",
                                    title: "Stumbling Vampire Assassin",
                                    description: "Deadly aim but also terrible aim. \n\nHis hit depends on a spinning wheel because he literally can’t control where his knives go."
                                )

                                characterRowCard(
                                    image: "knight head",
                                    title: "Super Hungry Knight",
                                    description: "His real enemy? Snacks.\n\n3 snacks = he explodes and dies. Keep an eye on those'snack break'."
                                )

                                characterRowCard(
                                    image: "boom head",
                                    title: "Dr. Boom Boom",
                                    description: "Half genius, half menace.\n\nHis coin-flip experiments have a 50/50 outcome. It works half the time, the other half? BIG BOOM!"
                                )
                            }
                            .frame(maxWidth: .infinity)

                            // Right Filled Card: Bonk
                            VStack(spacing: 10) {
                                Spacer(minLength: 0)

                                Image("bonk")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 110)

                                Text("Bonk")
                                    .font(.system(size: 18, weight: .bold, design: .serif))

                                Text(
                                    "Bonk is the 'final boss'...but Bonk doesn’t do much.\n\nHe's just blocking the exit but he also doesn’t attack. Reduce his HP to 0 to escape."
                                )
                                .font(.system(size: 13))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)

                                Spacer(minLength: 0)
                            }
                            .padding(16)
                            .frame(width: 230)
                            .frame(maxHeight: .infinity)
                            .background(
                                AppTheme.paper,
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(AppTheme.outline.opacity(0.55), lineWidth: 1)
                            }
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // MARK: - An Encounter

                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle("How-to-Play")
                        Text(
                            "The game is played in rounds called Encounters. Follow these 4 steps for One Encounter:")

                        HStack(alignment: .top, spacing: 10) {
                            ruleCard(
                                number: "01",
                                title: "Inspect",
                                text: "Each living idiot reveals two possible moves. Only one will happen."
                            )

                            ruleCard(
                                number: "02",
                                title: "Assign",
                                text: "Drag your available healer cards onto living teammates."
                            )
                        }
                        .fixedSize(horizontal: false, vertical: true)

                        HStack(alignment: .top, spacing: 10) {
                            ruleCard(
                                number: "03",
                                title: "Begin",
                                text: "Start the encounter. Watch each idiot’s chosen move, your response, and the result resolve one by one."
                            )

                            ruleCard(
                                number: "04",
                                title: "Repeat",
                                text: "Check everyone’s HP and the knight’s snacks. Keep going until you escape or everyone dies."
                            )
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // MARK: - Ghost Rule

                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle("Ghost Rule")

                        HStack(alignment: .center, spacing: 14) {
                            Image("ghost")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(
                                    "When an idiot dies, they become a ghost. Unfortunately, death doesn’t make them any less annoying. They steal cards from your hand, leaving you fewer ways to save whoever’s left."
                                )
                                .font(.system(size: 14))
                                .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(14)
                        .background(
                            AppTheme.paper,
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppTheme.outline.opacity(0.55), lineWidth: 1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .foregroundStyle(AppTheme.darkBrown)
                .padding(24)
                .background(
                    AppTheme.paper.opacity(0.58),
                    in: RoundedRectangle(cornerRadius: 22)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(AppTheme.outline.opacity(0.85), lineWidth: 1.2)
                        .allowsHitTesting(false)
                }
                .frame(maxWidth: 780)
                .padding(.horizontal, 28)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
            }

            // MARK: - Close Button

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.darkBrown, in: Circle())
                    .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
            .padding(.trailing, 20)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(AppTheme.backgroundTan)
    }

    // MARK: - Section Title

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 20, weight: .bold, design: .serif))
    }

    // MARK: - Healer Action Card (Vertical)

    private func healerActionCard(
        image: String,
        title: String,
        description: String
    ) -> some View {
        VStack(spacing: 10) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(height: 120)

            Text(title)
                .font(.system(size: 16, weight: .bold, design: .serif))

            Text(description)
                .font(.system(size: 13))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            AppTheme.paper,
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.outline.opacity(0.55), lineWidth: 1)
        }
    }

    // MARK: - Character Row Card

    private func characterRowCard(
        image: String,
        title: String,
        description: String
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .serif))

                Text(description)
                    .font(.system(size: 13))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            AppTheme.paper,
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.outline.opacity(0.55), lineWidth: 1)
        }
    }

    // MARK: - Rule Card

    private func ruleCard(
        number: String,
        title: String,
        text: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 17, weight: .bold, design: .serif))
                .frame(width: 26, alignment: .leading)

            Rectangle()
                .fill(AppTheme.outline.opacity(0.7))
                .frame(width: 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .serif))

                Text(text)
                    .font(.system(size: 13))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            AppTheme.paper,
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.outline.opacity(0.55), lineWidth: 1)
        }
    }
}

#Preview("Landscape", traits: .landscapeLeft) {
    HowToPlaySheetView()
}
