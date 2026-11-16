
//
//  GameBoardView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/11/26.
//  Updated by Jingyi: Responsive battle layout and larger card targets.
//  Updated by Jingyi: Bonk HP inside the original image sign.
//

import SwiftUI
import UIKit

struct GameBoardView: View {

    @EnvironmentObject var game: GameManager
    @Environment(\.dismiss) private var dismiss

    // MARK: - Profile
    // Added by Jingyi.

    @AppStorage("playerAvatarChoice")
    private var avatarChoice = "healer card"

    @State private var customAvatar: UIImage?
    @State private var showProfile = false

    // MARK: - Pause Menu
    // Added by Jingyi.

    @State private var isPaused = false
    @State private var showSettings = false
    @State private var showHowToPlay = false
    @State private var confirmReturnHome = false

    // MARK: - Colors

    private let backgroundTan = Color(
        red: 252.0 / 255,
        green: 220.0 / 255,
        blue: 187.0 / 255
    )

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

    private let paper = Color(
        red: 1,
        green: 243.0 / 255,
        blue: 228.0 / 255
    )

    // MARK: - Main View

    var body: some View {
        GeometryReader { geometry in

            let portrait =
                geometry.size.width < geometry.size.height

            let compact =
                geometry.size.height < 410

            ZStack {
                backgroundTan
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    // MARK: - Shared Header
                    // Keep the controls inside the safe area.

                    if !game.isGameOver {
                        topBar(compact: compact)
                    }

                    if game.isResolving {

                        EncounterResolutionView()
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: .infinity
                            )
                            .allowsHitTesting(!isPaused)

                    } else if portrait {

                        portraitBattleBoard(
                            size: geometry.size
                        )
                        .allowsHitTesting(!isPaused)

                    } else {

                        landscapeBattleBoard(
                            size: geometry.size,
                            compact: compact
                        )
                        .allowsHitTesting(!isPaused)
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )

                // MARK: - Game Over

                if game.isGameOver {
                    GameOverOverlayView(
                        didWin: game.didPlayerWin,
                        onPlayAgain: {
                            isPaused = false
                            game.resetGame()
                        },
                        onReturnHome: {
                            isPaused = false
                            game.resetGame()
                            dismiss()
                        }
                    )
                    .zIndex(10)
                }

                // MARK: - Pause

                if isPaused && !game.isGameOver {
                    pauseOverlay(compact: compact)
                        .zIndex(20)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)

        // MARK: - Sheets

        .sheet(
            isPresented: $showProfile,
            onDismiss: {
                loadAvatar()
            }
        ) {
            PlayerProfileView()
        }

        .sheet(
            isPresented: $showSettings
        ) {
            SettingsView()
        }

        .sheet(
            isPresented: $showHowToPlay
        ) {
            BattleHowToPlayView()
        }

        // MARK: - Return Confirmation

        .confirmationDialog(
            "Leave the current game?",
            isPresented: $confirmReturnHome,
            titleVisibility: .visible
        ) {
            Button(
                "Return Home",
                role: .destructive
            ) {
                isPaused = false
                game.resetGame()
                dismiss()
            }

            Button(
                "Keep Playing",
                role: .cancel
            ) {}

        } message: {
            Text(
                "Your current battle progress will be lost."
            )
        }

        // MARK: - Lifecycle

        .onAppear {
            loadAvatar()
        }

        .onChange(of: avatarChoice) { _, _ in
            loadAvatar()
        }

        .onChange(of: game.isGameOver) { _, ended in
            if ended {
                isPaused = false
            }
        }
    }

    // MARK: - Top Bar
    // Updated by Jingyi:
    // The same header is used in portrait and landscape.

    private func topBar(
        compact: Bool
    ) -> some View {

        HStack(spacing: 10) {

            Text(
                game.isResolving
                    ? "Encounter"
                    : "Assign Your Healer Cards"
            )
            .font(
                .system(
                    size: compact ? 14 : 17,
                    weight: .bold,
                    design: .rounded
                )
            )
            .foregroundStyle(darkBrown)
            .lineLimit(1)
            .minimumScaleFactor(0.8)

            Spacer(minLength: 4)

            // MARK: - Player Profile

            Button {
                loadAvatar()
                showProfile = true
            } label: {
                playerAvatarButton
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Player Profile")

            // MARK: - Pause Button

            Button {
                withAnimation(
                    .easeInOut(duration: 0.2)
                ) {
                    isPaused = true
                }
            } label: {
                Image(systemName: "pause.fill")
                    .font(
                        .system(
                            size: 17,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(darkBrown)
                    .frame(
                        width: 44,
                        height: 44
                    )
                    .background(
                        lightTan,
                        in: Circle()
                    )
                    .overlay {
                        Circle()
                            .stroke(
                                darkBrown,
                                lineWidth: 1.5
                            )
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Pause Game")
        }
        .padding(.horizontal, 12)
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .background(backgroundTan)
    }

    // MARK: - Portrait Battle
    // Updated by Jingyi:
    // Large teammate cards, Bonk, and healer hand.

    private func portraitBattleBoard(
        size: CGSize
    ) -> some View {

        let availableHeight = max(
            0,
            size.height - 56
        )

        let bossHeight: CGFloat = min(
            150,
            max(
                108,
                availableHeight * 0.19
            )
        )

        let handHeight: CGFloat = min(
            130,
            max(
                100,
                availableHeight * 0.16
            )
        )

        return VStack(spacing: 10) {

            // MARK: - Teammate Cards

            teammatePanel
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )

            // MARK: - Bonk and Action

            HStack(spacing: 12) {

                bonkWithHP
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )

                beginEncounterButton(
                    compact: false
                )
                .frame(
                    width: min(
                        172,
                        size.width * 0.44
                    )
                )
            }
            .frame(height: bossHeight)

            // MARK: - Healer Cards

            healerHand(
                height: handHeight,
                availableWidth: size.width - 24
            )
            .frame(height: handHeight)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Landscape Battle
    // Updated by Jingyi:
    // Allocate more width to teammate cards.

    private func landscapeBattleBoard(
        size: CGSize,
        compact: Bool
    ) -> some View {

        let gap: CGFloat = 10

        let usableWidth = max(
            0,
            size.width - 24 - gap
        )

        let bossWidth = min(
            210,
            max(
                135,
                usableWidth * 0.22
            )
        )

        let teammateWidth = max(
            0,
            usableWidth - bossWidth
        )

        let availableHeight = max(
            0,
            size.height - 56
        )

        let handHeight = min(
            105,
            max(
                76,
                availableHeight * 0.32
            )
        )

        return HStack(spacing: gap) {

            // MARK: - Left Team Section

            VStack(spacing: 7) {

                teammatePanel
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )

                healerHand(
                    height: handHeight,
                    availableWidth: teammateWidth
                )
                .frame(height: handHeight)
            }
            .frame(width: teammateWidth)

            // MARK: - Right Boss Section

            VStack(spacing: 8) {

                // MARK: - Bonk with HP
                // HP is rendered on the image,
                // not as a separate label above it.

                bonkWithHP
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )

                beginEncounterButton(
                    compact: compact
                )
            }
            .frame(width: bossWidth)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Bonk HP Display
    // Added by Jingyi:
    // Position HP over the original rectangular sign.
    // Use the same component for both orientations.

    private var bonkWithHP: some View {
        GeometryReader { geometry in

            let side = min(
                geometry.size.width,
                geometry.size.height
            )

            ZStack {

                Image("bonk cave")
                    .resizable()
                    .scaledToFit()
                    .rotationEffect(
                        .degrees(270)
                    )
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )

                // MARK: - HP Label
                // The offset follows the displayed image size.

                Text(
                    "\(max(0, game.bonkHP)) / 5 HP"
                )
                .font(
                    .system(
                        size: min(
                            17,
                            max(11, side * 0.075)
                        ),
                        weight: .black,
                        design: .serif
                    )
                )
                .foregroundStyle(darkBrown)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .offset(
                    y: -side * 0.20
                )
                .allowsHitTesting(false)
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Bonk, \(max(0, game.bonkHP)) of 5 HP"
        )
    }

    // MARK: - Responsive Teammate Panel
    // Updated by Jingyi:
    // Preserve readable card widths.
    // Enable scrolling when three cards cannot fit.

    private var teammatePanel: some View {
        GeometryReader { region in

            let outerPadding: CGFloat = 10
            let gap: CGFloat = 8
            let minimumCardWidth: CGFloat = 185

            let innerWidth = max(
                0,
                region.size.width - outerPadding * 2
            )

            let fittingCardWidth = max(
                0,
                (innerWidth - gap * 2) / 3
            )

            let canShowAll =
                fittingCardWidth >= minimumCardWidth

            let cardWidth = canShowAll
                ? fittingCardWidth
                : min(
                    245,
                    max(
                        205,
                        region.size.width * 0.66
                    )
                )

            let cardHeight = max(
                0,
                region.size.height - outerPadding * 2
            )

            ScrollView(
                .horizontal,
                showsIndicators: !canShowAll
            ) {
                HStack(
                    alignment: .top,
                    spacing: gap
                ) {

                    ForEach(
                        game.teammates
                    ) { teammate in

                        TeammateCardView(
                            teammate: teammate
                        )
                        .frame(
                            width: cardWidth,
                            height: cardHeight
                        )
                    }
                }
                .padding(outerPadding)
                .frame(
                    minWidth: region.size.width,
                    alignment: canShowAll
                        ? .center
                        : .leading
                )
            }
            .background(
                lightTan,
                in: RoundedRectangle(
                    cornerRadius: 12
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        Color.brown,
                        lineWidth: 2
                    )
            }
        }
    }

    // MARK: - Healer Hand
    // Updated by Jingyi:
    // Larger cards and a stable return-to-hand target.

    private func healerHand(
        height: CGFloat,
        availableWidth: CGFloat
    ) -> some View {

        let cardHeight = max(
            64,
            height - 8
        )

        let heroWidth = min(
            85,
            availableWidth * 0.16
        )

        return HStack(spacing: 8) {

            Image("healer card")
                .resizable()
                .scaledToFit()
                .frame(
                    width: heroWidth,
                    height: height
                )

            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {

                HStack(spacing: 10) {

                    ForEach(
                        game.availableCards,
                        id: \.self
                    ) { card in

                        Image(card.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(
                                height: cardHeight
                            )
                            .shadow(
                                color: .black.opacity(0.2),
                                radius: 4,
                                y: 2
                            )
                            .draggable(card.rawValue)
                            .accessibilityLabel(
                                card.rawValue
                            )
                    }
                }
                .frame(minHeight: height)
            }
            .contentShape(Rectangle())
            .dropDestination(
                for: String.self
            ) { items, _ in

                guard let rawCard = items.first,
                      let healerCard = HealerCard(
                        rawValue: rawCard
                      ) else {
                    return false
                }

                withAnimation {
                    game.returnToHand(
                        card: healerCard
                    )
                }

                return true
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .frame(height: height)
    }

    // MARK: - Begin Encounter
    // Original game action retained.

    private func beginEncounterButton(
        compact: Bool
    ) -> some View {

        Button {
            withAnimation {
                game.resolveEncounter()
            }
        } label: {

            Text("Begin Encounter")
                .font(
                    .system(
                        size: compact ? 13 : 15,
                        weight: .bold
                    )
                )
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(.white)
                .frame(
                    maxWidth: .infinity
                )
                .frame(
                    height: compact ? 42 : 48
                )
                .background(
                    game.allLivingAssigned &&
                    !game.isGameOver
                        ? Color.green
                        : Color.gray,
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .stroke(
                            Color.gray.opacity(0.5),
                            lineWidth: 2
                        )
                }
        }
        .buttonStyle(.plain)
        .disabled(
            !game.allLivingAssigned ||
            game.isGameOver
        )
    }

    // MARK: - Pause Menu
    // Added by Jingyi:
    // Scrollable on shorter landscape displays.

    private func pauseOverlay(
        compact: Bool
    ) -> some View {

        GeometryReader { geometry in

            ZStack {

                Color.black.opacity(0.56)
                    .ignoresSafeArea()

                ScrollView(
                    .vertical,
                    showsIndicators: false
                ) {

                    VStack(
                        spacing: compact ? 9 : 15
                    ) {

                        Image(
                            systemName: "pause.circle.fill"
                        )
                        .font(
                            .system(
                                size: compact ? 27 : 36
                            )
                        )

                        Text("Game Paused")
                            .font(
                                .system(
                                    size: compact ? 25 : 29,
                                    weight: .bold,
                                    design: .serif
                                )
                            )

                        Text("Even heroes need a break.")
                            .font(
                                .system(
                                    size: 13,
                                    design: .serif
                                )
                            )
                            .italic()
                            .foregroundStyle(
                                darkBrown.opacity(0.7)
                            )

                        pauseMenuButton(
                            "Resume Game",
                            icon: "play.fill",
                            prominent: true,
                            compact: compact
                        ) {
                            withAnimation {
                                isPaused = false
                            }
                        }

                        pauseMenuButton(
                            "Settings",
                            icon: "gearshape.fill",
                            compact: compact
                        ) {
                            showSettings = true
                        }

                        pauseMenuButton(
                            "How to Play",
                            icon: "book.closed.fill",
                            compact: compact
                        ) {
                            showHowToPlay = true
                        }

                        pauseMenuButton(
                            "Return Home",
                            icon: "house.fill",
                            compact: compact
                        ) {
                            confirmReturnHome = true
                        }
                    }
                    .foregroundStyle(darkBrown)
                    .padding(
                        compact ? 15 : 22
                    )
                    .frame(maxWidth: 420)
                    .background(
                        paper,
                        in: RoundedRectangle(
                            cornerRadius: 20
                        )
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: 20
                        )
                        .stroke(
                            darkBrown,
                            lineWidth: 2
                        )
                    }
                    .shadow(
                        color: .black.opacity(0.2),
                        radius: 15,
                        y: 8
                    )
                    .padding(12)
                    .frame(maxWidth: .infinity)
                }
                .frame(
                    maxWidth: min(
                        520,
                        geometry.size.width
                    ),
                    maxHeight: geometry.size.height
                )
            }
        }
    }

    // MARK: - Pause Menu Button

    private func pauseMenuButton(
        _ title: String,
        icon: String,
        prominent: Bool = false,
        compact: Bool,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {

            HStack(spacing: 11) {

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .frame(width: 23)

                Text(title)
                    .font(
                        .system(
                            size: compact ? 14 : 16,
                            weight: .semibold
                        )
                    )

                Spacer(minLength: 4)

                if !prominent {
                    Image(
                        systemName: "chevron.right"
                    )
                    .font(.caption.bold())
                }
            }
            .foregroundStyle(
                prominent
                    ? Color.white
                    : darkBrown
            )
            .padding(.horizontal, 15)
            .frame(
                height: compact ? 40 : 49
            )
            .background(
                prominent
                    ? darkBrown
                    : backgroundTan,
                in: RoundedRectangle(
                    cornerRadius: 12
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 12
                )
                .stroke(
                    darkBrown.opacity(
                        prominent ? 0 : 0.4
                    ),
                    lineWidth: 1
                )
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Player Avatar

    private var playerAvatarButton: some View {

        ZStack {

            Circle()
                .fill(lightTan)

            if avatarChoice == "photo",
               let customAvatar {

                Image(uiImage: customAvatar)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: 40,
                        height: 40
                    )
                    .clipShape(Circle())

            } else if avatarChoice == "healer card" {

                Image(
                    systemName: "person.crop.circle.fill"
                )
                .resizable()
                .scaledToFit()
                .foregroundStyle(darkBrown)
                .padding(9)

            } else {

                Image(avatarChoice)
                    .resizable()
                    .scaledToFit()
                    .padding(5)
            }
        }
        .frame(
            width: 44,
            height: 44
        )
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(
                    darkBrown,
                    lineWidth: 1.5
                )
        }
    }

    // MARK: - Load Saved Avatar

    private func loadAvatar() {

        guard let directory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            customAvatar = nil
            return
        }

        let avatarURL = directory
            .appendingPathComponent(
                "PlayerProfile",
                isDirectory: true
            )
            .appendingPathComponent("avatar.jpg")

        customAvatar = UIImage(
            contentsOfFile: avatarURL.path
        )
    }
}

// MARK: - How to Play
// Added by Jingyi: Responsive instruction sheet.

private struct BattleHowToPlayView: View {

    @Environment(\.dismiss)
    private var dismiss

    private let backgroundTan = Color(
        red: 252.0 / 255,
        green: 220.0 / 255,
        blue: 187.0 / 255
    )

    private let paper = Color(
        red: 1,
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

    var body: some View {

        GeometryReader { geometry in

            let compact =
                geometry.size.height < 410

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

                        VStack(spacing: 8) {

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

                                Rectangle()
                                    .fill(outline)
                                    .frame(height: 1)
                            }
                        }

                        VStack(
                            spacing: compact ? 8 : 12
                        ) {

                            ruleCard(
                                "01",
                                "Each idiot draws 2 possible moves and will always pick the most self-destructive one.",
                                compact: compact
                            )

                            ruleCard(
                                "02",
                                "Drag Heal (+1 HP), Reverse, or Do Nothing onto each idiot before starting the encounter.",
                                compact: compact
                            )

                            ruleCard(
                                "03",
                                "Use Reverse to redirect self-damage or friendly fire straight onto Bonk!",
                                compact: compact
                            )

                            ruleCard(
                                "04",
                                "Win by dropping Bonk to 0 HP. Lose if two idiots become ghosts.",
                                compact: compact
                            )
                        }

                        Button {
                            dismiss()
                        } label: {

                            Text("Got It")
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                                .frame(
                                    maxWidth: .infinity
                                )
                                .frame(
                                    height: compact ? 40 : 50
                                )
                                .background(
                                    brown,
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .foregroundStyle(brown)
                    .padding(
                        compact ? 14 : 20
                    )
                    .background(
                        paper.opacity(0.58),
                        in: RoundedRectangle(
                            cornerRadius: 22
                        )
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: 22
                        )
                        .stroke(
                            outline.opacity(0.85),
                            lineWidth: 1.2
                        )
                    }
                    .frame(maxWidth: 520)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(
                        maxWidth: .infinity
                    )
                }
                .frame(
                    maxHeight: geometry.size.height
                )
            }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - Rule Card

    private func ruleCard(
        _ number: String,
        _ text: String,
        compact: Bool
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 11
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
                    width: 27,
                    alignment: .leading
                )

            Rectangle()
                .fill(
                    outline.opacity(0.7)
                )
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
        .foregroundStyle(brown)
        .padding(
            compact ? 10 : 15
        )
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
            RoundedRectangle(
                cornerRadius: 14
            )
            .stroke(
                outline.opacity(0.55),
                lineWidth: 1
            )
        }
    }
}

// MARK: - Game Over Overlay
// Original game actions retained.
// Updated by Jingyi: Responsive result layout.

struct GameOverOverlayView: View {

    let didWin: Bool
    let onPlayAgain: () -> Void
    let onReturnHome: () -> Void

    private let darkBrown = Color(
        red: 0.35,
        green: 0.23,
        blue: 0.18
    )

    private let cardTan = Color(
        red: 0.98,
        green: 0.88,
        blue: 0.74
    )

    var body: some View {

        GeometryReader { geometry in

            let compact =
                geometry.size.height < 410

            ZStack {

                Color.black.opacity(0.6)
                    .ignoresSafeArea()

                ScrollView(
                    .vertical,
                    showsIndicators: false
                ) {

                    VStack(
                        spacing: compact ? 11 : 18
                    ) {

                        Text(
                            didWin
                                ? "YOU WIN!"
                                : "YOU LOST!"
                        )
                        .font(
                            .system(
                                size: compact ? 29 : 38,
                                weight: .black,
                                design: .serif
                            )
                        )
                        .foregroundStyle(
                            didWin
                                ? Color.green
                                : Color.red
                        )

                        Text(
                            didWin
                                ? "Bonk has been defeated!"
                                : "Two idiots became ghosts!"
                        )
                        .font(.headline)
                        .foregroundStyle(darkBrown)
                        .multilineTextAlignment(.center)

                        HStack(spacing: 12) {

                            Button(
                                action: onPlayAgain
                            ) {
                                Text("Play Again")
                                    .font(
                                        .headline.bold()
                                    )
                                    .foregroundStyle(.white)
                                    .frame(
                                        maxWidth: .infinity
                                    )
                                    .frame(height: 44)
                                    .background(
                                        Color.green,
                                        in: Capsule()
                                    )
                            }

                            Button(
                                action: onReturnHome
                            ) {
                                Text("Return Home")
                                    .font(
                                        .headline.bold()
                                    )
                                    .foregroundStyle(darkBrown)
                                    .frame(
                                        maxWidth: .infinity
                                    )
                                    .frame(height: 44)
                                    .background(
                                        Color.white,
                                        in: Capsule()
                                    )
                                    .overlay {
                                        Capsule()
                                            .stroke(
                                                darkBrown,
                                                lineWidth: 2
                                            )
                                    }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(
                        compact ? 18 : 28
                    )
                    .frame(maxWidth: 430)
                    .background(
                        cardTan,
                        in: RoundedRectangle(
                            cornerRadius: 20
                        )
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: 20
                        )
                        .stroke(
                            darkBrown,
                            lineWidth: 3
                        )
                    }
                    .shadow(radius: 15)
                    .padding(12)
                    .frame(
                        maxWidth: .infinity
                    )
                }
                .frame(
                    maxHeight: geometry.size.height
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GameBoardView()
            .environmentObject(GameManager())
    }
}

