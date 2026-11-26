//
//  TeammateCardView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/11/26.
//  Updated by Jingyi: Larger responsive cards and drop targets.
//

import SwiftUI

struct TeammateCardView: View {

    @ObservedObject var teammate: Teammate
    @EnvironmentObject var game: GameManager

    private let cardBackground = Color(
        red: 0.98,
        green: 0.85,
        blue: 0.68
    )

    private let darkBrownText = Color(
        red: 0.35,
        green: 0.23,
        blue: 0.18
    )

    private let mediumBrown = Color(
        red: 0.42,
        green: 0.30,
        blue: 0.24
    )

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 235
            let narrow = geometry.size.width < 205
            let inset: CGFloat = compact ? 7 : 10

            VStack(spacing: compact ? 5 : 9) {

                characterHeader(narrow: narrow)
                    .frame(height: compact ? 56 : 66, alignment: .center)

                if teammate.isGhost {
                    ghostContent(compact: compact)
                } else {

                    // MARK: - Move Options
                    // Illustrated cards scale to fit the available space
                    // while keeping the bottom description crisp.

                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Text("Possible moves")
                                .font(
                                    .system(
                                        size: 12,
                                        weight: .bold,
                                        design: .serif
                                    )
                                )

                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(darkBrownText)

                        HStack(
                            alignment: .center,
                            spacing: 7
                        ) {
                            IdiotMoveCardView(
                                card: teammate.optionA,
                                textColor: darkBrownText,
                                borderColor: mediumBrown
                            )

                            IdiotMoveCardView(
                                card: teammate.optionB,
                                textColor: darkBrownText,
                                borderColor: mediumBrown
                            )
                        }
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.2)) {
                                game.inspectedTeammate = teammate
                            }
                        }
                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )

                    // MARK: - Drop Target
                    // Keep the visible target large
                    // and anchored near the bottom.

                    responseSlot
                        .frame(
                            height: compact ? 58 : 72
                        )
                }
            }
            .padding(inset)
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .background(
                teammate.isGhost
                    ? cardBackground.opacity(0.65)
                    : cardBackground,
                in: RoundedRectangle(
                    cornerRadius: 12
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        darkBrownText,
                        lineWidth: 2
                    )
            }
            .contentShape(
                RoundedRectangle(cornerRadius: 12)
            )

            // MARK: - Full Card Drop Target
            // Added by Jingyi:
            // Players can drop a healer card anywhere
            // on a living teammate card.

            .dropDestination(for: String.self) {
                items, _ in

                guard !teammate.isGhost,
                      let rawCard = items.first,
                      let healerCard = HealerCard(
                        rawValue: rawCard
                      ) else {
                    return false
                }

                withAnimation {
                    game.assignCard(
                        card: healerCard,
                        to: teammate
                    )
                }

                return true
            }
        }
    }

    // MARK: - Character Header

    private func characterHeader(
        narrow: Bool
    ) -> some View {
        let snacks = game.snackBreakCount(for: teammate)
        let maxSnacks = game.maxSnackBreaks

        return HStack(
            alignment: .center,
            spacing: 8
        ) {
            Image(teammate.headImageName)
                .resizable()
                .scaledToFit()
                .frame(
                    width: narrow ? 42 : 50,
                    height: narrow ? 42 : 50
                )

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text(teammate.name)
                    .font(
                        .system(
                            size: narrow ? 12 : 14,
                            weight: .bold,
                            design: .serif
                        )
                    )
                    .foregroundStyle(darkBrownText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 6) {
                    HStack(spacing: 2) {
                        ForEach(
                            0..<teammate.maxHp,
                            id: \.self
                        ) { index in
                            Image(
                                systemName: "heart.fill"
                            )
                            .font(
                                .system(size: narrow ? 10 : 12)
                            )
                            .foregroundStyle(
                                index < teammate.hp
                                    ? Color.red
                                    : Color.gray
                            )
                        }
                    }
                    .accessibilityLabel(
                        "\(teammate.hp) of \(teammate.maxHp) HP"
                    )

                    if teammate.character == .knight {
                        SnackBreakCounterBadge(
                            count: snacks,
                            maxCount: maxSnacks,
                            compact: narrow
                        )
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    // MARK: - Ghost Content

    private func ghostContent(
        compact: Bool
    ) -> some View {
        VStack(spacing: compact ? 4 : 6) {
            Spacer(minLength: 0)

            if let card = game.stolenCards[teammate.id] {
                GhostWithStolenCard(card: card)
                    .scaleEffect(compact ? 0.82 : 1)
                    .frame(height: compact ? 73 : 85)
                    .opacity(game.pendingThefts.contains { $0.id == teammate.id } ? 0 : 1)
                    .anchorPreference(key: TheftAnchors.self, value: .bounds) {
                        [.panel(teammate.id): $0]
                    }
            } else {
                Image("ghost")
                    .resizable()
                    .scaledToFit()
                    .frame(height: compact ? 60 : 90)
            }

            // Keep both status labels together and inside the card border.
            VStack(spacing: 3) {
                Text("GHOST")
                    .font(
                        .system(
                            size: 15,
                            weight: .bold,
                            design: .serif
                        )
                    )

                Text("Out of play")
                    .font(.system(size: 12))
            }
            .foregroundStyle(mediumBrown)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: compact ? 8 : 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Healer Response Slot

    private var responseSlot: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9)
                .fill(
                    Color.white.opacity(0.36)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(
                            mediumBrown,
                            style: StrokeStyle(
                                lineWidth: 2,
                                dash: [6, 4]
                            )
                        )
                }

            if let card = teammate.assignedCard {

                // MARK: - Assigned Card
                // Tap to remove or drag back to hand.

                HStack(spacing: 7) {
                    Image(card.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: 38,
                            height: 44
                        )

                    Text(card.rawValue)
                        .font(
                            .system(
                                size: 12,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(darkBrownText)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                }
                .padding(.horizontal, 8)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
                .draggable(card.rawValue)
                .onTapGesture {
                    withAnimation {
                        game.unassignCard(
                            from: teammate
                        )
                    }
                }

            } else {
                VStack(spacing: 4) {
                    Image(
                        systemName: "hand.draw"
                    )
                    .font(.system(size: 18))

                    Text("DROP HEALER CARD")
                        .font(
                            .system(
                                size: 10,
                                weight: .bold
                            )
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .foregroundStyle(darkBrownText)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel(
            teammate.assignedCard == nil
                ? "Drop a healer card here"
                : "Assigned healer card"
        )
    }
}

// MARK: - Snack Break Counter Badge

struct SnackBreakCounterBadge: View {
    let count: Int
    let maxCount: Int
    var compact: Bool = false

    private var isDanger: Bool {
        count >= maxCount - 1
    }

    var body: some View {
        HStack(spacing: 3) {
            Text("🍪")
                .font(.system(size: compact ? 10 : 11))

            HStack(spacing: 2) {
                ForEach(0..<maxCount, id: \.self) { index in
                    Circle()
                        .fill(
                            index < count
                                ? (isDanger ? Color.red : Color(red: 0.62, green: 0.34, blue: 0.14))
                                : Color.brown.opacity(0.25)
                        )
                        .frame(width: compact ? 5 : 6, height: compact ? 5 : 6)
                }
            }

            Text("\(count)/\(maxCount)")
                .font(.system(size: compact ? 9 : 10, weight: .bold, design: .rounded))
                .foregroundStyle(isDanger ? Color.red : Color(red: 0.35, green: 0.23, blue: 0.18))
        }
        .padding(.horizontal, compact ? 5 : 6)
        .padding(.vertical, 2)
        .background(
            isDanger ? Color.red.opacity(0.12) : Color.white.opacity(0.72),
            in: Capsule()
        )
        .overlay {
            Capsule()
                .stroke(
                    isDanger ? Color.red.opacity(0.75) : Color.brown.opacity(0.45),
                    lineWidth: 1
                )
        }
        .accessibilityLabel("Snack breaks: \(count) of \(maxCount)")
    }
}

// MARK: - Illustrated Idiot Move Card View
// Renders the character's card PNG and overlays the move description
// inside the blank bottom parchment box.

struct IdiotMoveCardView: View {

    let card: IdiotCard?
    var textColor: Color = Color(red: 0.35, green: 0.23, blue: 0.18)
    var borderColor: Color = Color(red: 0.65, green: 0.5, blue: 0.4)

    var body: some View {
        Group {
            if let card = card {
                Image(card.imageName)
                    .resizable()
                    .scaledToFit()
                    .overlay {
                        GeometryReader { geo in
                            Text(card.description)
                                .font(
                                    .system(
                                        size: max(6.5, geo.size.height * 0.068),
                                        weight: .bold,
                                        design: .serif
                                    )
                                )
                                .foregroundStyle(textColor)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .minimumScaleFactor(0.5)
                                .frame(
                                    width: geo.size.width * 0.74,
                                    height: geo.size.height * 0.22
                                )
                                .position(
                                    x: geo.size.width * 0.5,
                                    y: geo.size.height * 0.815
                                )
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(card.title): \(card.description)")
            } else {
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.white.opacity(0.2))
                    .overlay {
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(borderColor, lineWidth: 1)
                    }
                    .overlay {
                        Text("Empty")
                            .font(.system(size: 12))
                            .foregroundStyle(.gray)
                    }
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}

#Preview {
    TeammateCardView(
        teammate: Teammate(
            character: .drBoomBoom,
            hp: 3
        )
    )
    .environmentObject(GameManager())
    .frame(width: 225, height: 310)
}

struct GhostWithStolenCard: View {
    let card: HealerCard

    var body: some View {
        ZStack {
            Image(card.imageName)
                .resizable().scaledToFit().frame(height: 50)
                .grayscale(1).opacity(0.48)
                .rotationEffect(.degrees(-8)).offset(y: 17)
            Image("ghost")
                .resizable().scaledToFit().frame(width: 102)
                .offset(y: -12)
        }
        .frame(height: 85)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Ghost holding \(card.rawValue)")
    }
}

