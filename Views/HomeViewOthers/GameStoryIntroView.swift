//
//  GameStoryIntroView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/25/26.
//

import SwiftUI

// MARK: - Animated Game Story Introduction

struct GameStoryIntroView: View {

    @Environment(\.dismiss)
    private var dismiss

    @State private var scene = 0
    @State private var drifting = false

    private let brown = Color(
        red: 89/255,
        green: 59/255,
        blue: 46/255
    )

    private let paper = Color(
        red: 255/255,
        green: 243/255,
        blue: 228/255
    )

    private let peach = Color(
        red: 252/255,
        green: 220/255,
        blue: 187/255
    )

    private let chapters: [
        (
            eyebrow: String,
            headline: String,
            story: String,
            image: String
        )
    ] = [
        (
            "CHAPTER I · YOUR MISSION",
            "The Healer's Bad Luck",
            "You are the only healer on a team of three very brave—and very reckless—adventurers.",
            "healer card"
        ),
        (
            "CHAPTER II · YOUR TEAM",
            "Three Heroes. Zero Caution.",
            "They pick the riskiest moves. Your job is to read their intentions and keep them alive.",
            "vampire full"
        ),
        (
            "CHAPTER III · THE ENEMY",
            "BONK Is Waiting",
            "Assign your cards before each encounter. Defeat BONK before two teammates turn into ghosts.",
            "bonk"
        )
    ]

    var body: some View {
        GeometryReader { geo in

            let width = geo.size.width
            let height = geo.size.height
            let compact = height < 430

            let side = max(
                16,
                min(44, width * 0.035)
            )

            ZStack {
                // MARK: - Background

                peach.ignoresSafeArea()

                Image("gameboardbg")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: width,
                        height: height
                    )
                    .clipped()
                    .overlay(brown.opacity(0.10))
                    .allowsHitTesting(false)

                LinearGradient(
                    colors: [
                        paper.opacity(0.12),
                        peach.opacity(0.14),
                        paper.opacity(0.38)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .allowsHitTesting(false)

                HStack(
                    spacing: max(12, width * 0.035)
                ) {
                    ZStack {
                        Circle()
                            .fill(paper.opacity(0.65))
                            .frame(
                                width: min(
                                    height * 0.64,
                                    width * 0.28
                                )
                            )
                            .blur(radius: 27)

                        Image(chapters[scene].image)
                            .resizable()
                            .scaledToFit()
                            .frame(
                                maxWidth: min(
                                    width * 0.34,
                                    335
                                ),
                                maxHeight: height * 0.68
                            )
                            .shadow(
                                color: brown.opacity(0.25),
                                radius: 14,
                                y: 12
                            )
                            .offset(
                                y: drifting ? -7 : 7
                            )
                            .id(scene)
                            .transition(
                                .asymmetric(
                                    insertion: .opacity
                                        .combined(
                                            with: .scale(
                                                scale: 0.92
                                            )
                                        ),
                                    removal: .opacity
                                )
                            )
                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )

                    VStack(
                        alignment: .leading,
                        spacing: compact ? 10 : 16
                    ) {
                        HStack {
                            Text(
                                chapters[scene].eyebrow
                            )
                            .font(
                                .system(
                                    size: compact ? 10 : 12,
                                    weight: .heavy,
                                    design: .rounded
                                )
                            )
                            .tracking(1.5)

                            Spacer(minLength: 4)

                            Button("Skip") {
                                dismiss()
                            }
                            .font(
                                .system(
                                    size: 13,
                                    weight: .bold
                                )
                            )
                        }
                        .foregroundStyle(
                            brown.opacity(0.85)
                        )

                        Text(
                            chapters[scene].headline
                        )
                        .font(
                            .system(
                                size: compact ? 25 : 36,
                                weight: .black,
                                design: .serif
                            )
                        )
                        .minimumScaleFactor(0.8)
                        .lineLimit(2)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                        .foregroundStyle(brown)

                        Text(chapters[scene].story)
                            .font(
                                .system(
                                    size: compact ? 14 : 17,
                                    weight: .medium,
                                    design: .serif
                                )
                            )
                            .foregroundStyle(
                                brown.opacity(0.92)
                            )
                            .lineLimit(3)
                            .minimumScaleFactor(0.85)
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )

                        HStack(spacing: 8) {
                            ForEach(
                                0..<chapters.count,
                                id: \.self
                            ) { index in
                                Capsule()
                                    .fill(
                                        index == scene
                                            ? brown
                                            : brown.opacity(0.2)
                                    )
                                    .frame(height: 5)
                            }
                        }
                        .padding(
                            .top,
                            compact ? 2 : 6
                        )

                        Button {
                            if scene == chapters.count - 1 {
                                dismiss()
                            } else {
                                withAnimation(
                                    .easeInOut(
                                        duration: 0.38
                                    )
                                ) {
                                    scene += 1
                                }
                            }
                        } label: {
                            HStack {
                                Spacer()

                                Text(
                                    scene == chapters.count - 1
                                        ? "Learn to Play"
                                        : "Next Chapter"
                                )

                                Image(
                                    systemName: "arrow.right"
                                )

                                Spacer()
                            }
                            .font(
                                .system(
                                    size: 15,
                                    weight: .bold
                                )
                            )
                            .foregroundStyle(paper)
                            .frame(
                                height: compact ? 40 : 48
                            )
                            .background(
                                brown,
                                in: Capsule()
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(compact ? 18 : 26)
                    .frame(
                        width: min(
                            width * 0.48,
                            535
                        ),
                        alignment: .leading
                    )
                    .background(
                        paper.opacity(0.94),
                        in: RoundedRectangle(
                            cornerRadius: 23
                        )
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: 23
                        )
                        .stroke(
                            brown.opacity(0.72),
                            lineWidth: 1.5
                        )
                    }
                    .shadow(
                        color: brown.opacity(0.14),
                        radius: 12,
                        y: 5
                    )
                }
                .padding(.horizontal, side)
                .padding(
                    .vertical,
                    compact ? 10 : 22
                )
                .frame(
                    width: width,
                    height: height
                )
            }
            .frame(
                width: width,
                height: height
            )
            .clipped()
        }
        .background(peach.ignoresSafeArea())
        .ignoresSafeArea(
            .container,
            edges: .all
        )
        .environment(\.colorScheme, .light)
        .onAppear {
            withAnimation(
                .easeInOut(
                    duration: 1.65
                )
                .repeatForever(
                    autoreverses: true
                )
            ) {
                drifting = true
            }
        }
    }
}
