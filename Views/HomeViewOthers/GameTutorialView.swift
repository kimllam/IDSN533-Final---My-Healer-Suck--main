//
//  GameTutorial.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/25/26.
//


import SwiftUI

// MARK: - First Play Guided Tutorial

struct GameTutorialView: View {
    var onCompleted: () -> Void = {}
    init(onCompleted: @escaping () -> Void = {}) {
        self.onCompleted = onCompleted
    }
    @Environment(\.dismiss) private var dismiss

    @State private var step = 0
    @State private var inspectedCard = false
    @State private var practiceComplete = false
    @State private var cardOffset: CGSize = .zero
    @State private var isCardPressed = false


    private let titles = [
        "Your Team Needs a Healer",
        "Know Your Teammates",
        "Hold a Card to Inspect",
        "Drag a Card to Assign",
        "You're Ready for BONK"
    ]

    private let instructions = [
        "Your three reckless heroes are counting on you. Keep at least two alive while defeating BONK.",
        "Look at each hero's possible moves before choosing which card to give them.",
        "Try it now: press and hold the Heal card until its effect appears. You can also tap the ? symbol.",
        "Your turn! Drag the Heal card into the teammate's dashed drop area.",
        "Heal restores HP. Reverse changes the outcome of an action. Do Nothing leaves that hero alone. Assign cards, then begin the encounter."
    ]

    private var canAdvance: Bool {
        switch step {
        case 2:
            return inspectedCard
        case 3:
            return practiceComplete
        default:
            return true
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let landscape =
                geometry.size.width > geometry.size.height

            let compact =
                geometry.size.height < 440

            let sidePadding: CGFloat = landscape
                ? max(96, geometry.safeAreaInsets.leading + 34)
                : 20

            let availableWidth = max(
                300,
                geometry.size.width - sidePadding * 2
            )

            let panelWidth = min(availableWidth, 1180)
            let panelHeight = min(geometry.size.height - 22, 600)

            ZStack {
                Image("gameboardbg")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .clipped()
                    .overlay(AppTheme.backgroundTan.opacity(0.38))
                    .allowsHitTesting(false)

                VStack(spacing: compact ? 10 : 16) {
                    header(compact: compact)

                    HStack(spacing: 5) {
                        ForEach(0..<5, id: \.self) { index in
                            Capsule()
                                .fill(
                                    index <= step
                                    ? AppTheme.darkBrown
                                    : AppTheme.darkBrown.opacity(0.17)
                                )
                                .frame(height: 5)
                        }
                    }

                    if landscape {
                        HStack(spacing: compact ? 16 : 24) {
                            demonstration(
                                height: min(panelHeight * 0.54, 310)
                            )
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: .infinity
                            )
                            .background(
                                AppTheme.backgroundTan.opacity(0.46),
                                in: RoundedRectangle(cornerRadius: 17)
                            )

                            explanation(compact: compact)
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .leading
                                )
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                demonstration(height: 180)
                                    .frame(height: 205)

                                explanation(compact: compact)
                            }
                        }
                    }

                    footer(compact: compact)
                }
                .padding(compact ? 16 : 22)
                .frame(
                    width: panelWidth,
                    height: panelHeight
                )
                .background(
                    AppTheme.paper,
                    in: RoundedRectangle(cornerRadius: 24)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            AppTheme.darkBrown.opacity(0.55),
                            lineWidth: 1.6
                        )
                }
                .shadow(
                    color: AppTheme.darkBrown.opacity(0.22),
                    radius: 13,
                    y: 7
                )
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .background(AppTheme.backgroundTan.ignoresSafeArea())
        .ignoresSafeArea(.container, edges: .all)
        .environment(\.colorScheme, .light)
    }

    private func header(compact: Bool) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Label(
                "TRAINING CAMP",
                systemImage: "shield.lefthalf.filled"
            )
            .font(
                .system(
                    size: compact ? 12 : 15,
                    weight: .black,
                    design: .rounded
                )
            )
            .tracking(0.7)

            Text("\(step + 1) / 5")
                .font(
                    .system(
                        size: compact ? 12 : 14,
                        weight: .heavy
                    )
                )
                .foregroundStyle(AppTheme.darkBrown.opacity(0.72))

            Spacer(minLength: 0)

            Button("Skip Tutorial") {
                dismiss()
            }
            .font(
                .system(
                    size: compact ? 12 : 14,
                    weight: .bold
                )
            )
            .buttonStyle(.plain)
        }.foregroundStyle(AppTheme.darkBrown)
    }

    private func explanation(compact: Bool) -> some View {
        VStack(
            alignment: .leading,
            spacing: compact ? 10 : 16
        ) {
            Text("STEP \(step + 1)")
                .font(
                    .system(
                        size: compact ? 11 : 13,
                        weight: .black
                    )
                )
                .tracking(2)
                .foregroundStyle(AppTheme.darkBrown.opacity(0.65))

            Text(titles[step])
                .font(
                    .system(
                        size: compact ? 25 : 34,
                        weight: .black,
                        design: .serif
                    )
                )
                .minimumScaleFactor(0.8)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            Text(instructions[step])
                .font(
                    .system(
                        size: compact ? 14 : 17,
                        weight: .medium,
                        design: .serif
                    )
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
                .foregroundStyle(AppTheme.darkBrown.opacity(0.88))

            if step == 2 || step == 3 {
                HStack(spacing: 8) {
                    Image(
                        systemName: canAdvance
                            ? "checkmark.circle.fill"
                            : "hand.point.up.left.fill"
                    )

                    Text(
                        step == 2
                            ? (
                                inspectedCard
                                    ? "Great! Heal restores 1 HP."
                                    : "Hold the card or tap its ?"
                            )
                            : (
                                practiceComplete
                                    ? "Nice! You assigned Heal."
                                    : "Drag Heal onto the dotted target"
                            )
                    )
                }
                .font(
                    .system(
                        size: compact ? 12 : 14,
                        weight: .bold
                    )
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    canAdvance ? AppTheme.softGreen : AppTheme.backgroundTan,
                    in: RoundedRectangle(cornerRadius: 12)
                )
            }

            Spacer(minLength: 0)
        }
        .foregroundStyle(AppTheme.darkBrown)
    }

    private func footer(compact: Bool) -> some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button("Back") {
                    withAnimation(
                        .easeInOut(duration: 0.2)
                    ) {
                        step -= 1
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: compact ? 42 : 49)
                .foregroundStyle(AppTheme.darkBrown)
                .background(AppTheme.backgroundTan, in: Capsule())
            }

            Button(
                step == 4 ? "Start Battle" : "Next Step"
            ) {
                if step == 4 {
                    onCompleted()
                    dismiss()
                } else {
                    withAnimation(
                        .easeInOut(duration: 0.2)
                    ) {
                        step += 1
                    }
                }
            }
            .disabled(!canAdvance)
            .frame(maxWidth: .infinity)
            .frame(height: compact ? 42 : 49)
            .foregroundStyle(AppTheme.paper)
            .background(
                canAdvance
                ? AppTheme.darkBrown
                : AppTheme.darkBrown.opacity(0.40),
                in: Capsule()
            )
            .accessibilityHint(
                canAdvance
                    ? "Continue the tutorial"
                    : "Complete the practice to continue"
            )
        }
        .font(
            .system(
                size: compact ? 14 : 16,
                weight: .bold
            )
        )
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func demonstration(height: CGFloat) -> some View {
        switch step {
        case 0:
            HStack(spacing: 12) {
                Image("healer card")
                    .resizable()
                    .scaledToFit()

                Image("bonk")
                    .resizable()
                    .scaledToFit()
            }
            .frame(height: height * 0.88)
            .padding(10)

        case 1:
            VStack(spacing: 12) {
                HStack(spacing: 13) {
                    ForEach(
                        [
                            "vampire head",
                            "knight head",
                            "boom head"
                        ],
                        id: \.self
                    ) { name in
                        Image(name)
                            .resizable()
                            .scaledToFit()
                    }
                }
                .frame(height: height * 0.58)

                Text("CHECK POSSIBLE MOVES BEFORE PLAYING")
                    .font(
                        .system(
                            size: 11,
                            weight: .heavy
                        )
                    )
                    .foregroundStyle(AppTheme.darkBrown)
            }
            .padding(12)

        case 2:
            VStack(spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    Image("heal card")
                        .resizable()
                        .scaledToFit()
                        .frame(height: height * 0.70)
                        .scaleEffect(
                            isCardPressed ? 0.96 : 1
                        )
                        .contentShape(Rectangle())
                        .onLongPressGesture(
                            minimumDuration: 0.5,
                            pressing: { isPressing in
                                withAnimation(
                                    .easeOut(duration: 0.12)
                                ) {
                                    isCardPressed = isPressing
                                }
                            },
                            perform: {
                                withAnimation(
                                    .spring(response: 0.25)
                                ) {
                                    inspectedCard = true
                                }
                            }
                        )
                        .accessibilityLabel(
                            "Heal card, hold to inspect"
                        )

                    Button {
                        withAnimation(
                            .spring(response: 0.25)
                        ) {
                            inspectedCard = true
                        }
                    } label: {
                        Image(
                            systemName: "questionmark.circle.fill"
                        )
                        .font(
                            .system(
                                size: 27,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(AppTheme.darkBrown)
                        .background(AppTheme.paper, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Inspect Heal card")
                }
                .frame(maxWidth: 230)

                Text(
                    inspectedCard
                        ? "HEAL  ·  +1 HP"
                        : "PRESS & HOLD FOR 0.5 SEC"
                )
                .font(
                    .system(
                        size: 12,
                        weight: .black,
                        design: .rounded
                    )
                )
                .foregroundStyle(AppTheme.darkBrown)
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )

        case 3:
            GeometryReader { geo in
                let cardWidth = min(
                    geo.size.width * 0.23,
                    105.0
                )

                HStack(spacing: 12) {
                    Image("heal card")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: cardWidth,
                            height: height * 0.75
                        )
                        .offset(cardOffset)
                        .zIndex(2)
                        .gesture(
                            DragGesture(minimumDistance: 3)
                                .onChanged { value in
                                    cardOffset = value.translation
                                }
                                .onEnded { value in
                                    // Accept drops into the teammate area.
                                    if value.translation.width
                                        > geo.size.width * 0.24 {

                                        withAnimation(
                                            .spring(response: 0.3)
                                        ) {
                                            practiceComplete = true
                                        }
                                    }

                                    withAnimation(
                                        .spring(response: 0.3)
                                    ) {
                                        cardOffset = .zero
                                    }
                                }
                        )
                        .accessibilityLabel(
                            "Drag Heal card to the teammate"
                        )

                    Image(systemName: "arrow.right")
                        .font(
                            .system(
                                size: 25,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(AppTheme.darkBrown)

                    VStack(spacing: 5) {
                        Image("knight head")
                            .resizable()
                            .scaledToFit()
                            .frame(
                                maxHeight: height * 0.46
                            )

                        Text(
                            practiceComplete
                                ? "ASSIGNED!"
                                : "DROP HERE"
                        )
                        .font(
                            .system(
                                size: 11,
                                weight: .heavy
                            )
                        )
                        .foregroundStyle(AppTheme.darkBrown)
                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                    .background(
                        practiceComplete ? AppTheme.softGreen : AppTheme.paper,
                        in: RoundedRectangle(
                            cornerRadius: 14
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                AppTheme.darkBrown.opacity(0.7),
                                style: StrokeStyle(
                                    lineWidth: 2,
                                    dash: [6, 5]
                                )
                            )
                    }
                }
                .padding(16)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
            }
            .frame(height: height)

        default:
            HStack(spacing: 11) {
                ForEach(
                    [
                        "heal card",
                        "reverse card",
                        "nothing card"
                    ],
                    id: \.self
                ) { name in
                    Image(name)
                        .resizable()
                        .scaledToFit()
                }
            }
            .frame(height: height * 0.82)
            .padding(12)
        }
    }
}
