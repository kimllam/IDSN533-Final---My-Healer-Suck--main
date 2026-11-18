
//
//  GameBoardView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/11/26.
//  Updated by Jingyi: Responsive battle layout and larger card targets.
//  Updated by Jingyi: Bonk HP inside the original image sign.
//  Updated: Single Continue action and battle readability.
//

import SwiftUI
import UIKit

// MARK: - Game Board

struct GameBoardView: View {

    @EnvironmentObject var game: GameManager

    // MARK: - Profile

    @AppStorage("playerAvatarChoice")
    private var avatarChoice = "healer card"

    @State private var customAvatar: UIImage?
    @State private var showProfile = false

    // MARK: - Pause Menu

    @State private var isPaused = false
    @State private var showSettings = false
    @State private var showHowToPlay = false

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
        red: 1.0,
        green: 243.0 / 255,
        blue: 228.0 / 255
    )

    // MARK: - Main View

    private var displayedHealerCards: [HealerCard] {
        guard !game.pendingThefts.isEmpty else { return game.availableCards }
        return HealerCard.allCases.filter { card in
            game.availableCards.contains(card) || game.pendingThefts.contains { $0.card == card }
        }
    }

    var body: some View {
        GeometryReader { geometry in

            let portrait =
                geometry.size.width < geometry.size.height

            let compact =
                geometry.size.height < 410

            ZStack {

                            VStack(spacing: 0) {

                                // MARK: - Shared Header

                                if !game.isGameOver {
                                    topBar(compact: compact)
                                }

                                // MARK: - Battle Content

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
                                    .allowsHitTesting(!isPaused && game.pendingThefts.isEmpty)

                                } else {

                                    landscapeBattleBoard(
                                        size: geometry.size,
                                        compact: compact
                                    )
                                    .allowsHitTesting(!isPaused && game.pendingThefts.isEmpty)
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
                                    onContinue: {
                                        restartBattle()
                                    }
                                )
                                .zIndex(10)
                            }

                            // MARK: - Move Inspect Overlay

                            if let teammate = game.inspectedTeammate,
                               !game.isResolving,
                               !game.isGameOver {

                                MoveInspectOverlayView(
                                    teammate: teammate
                                ) {
                                    withAnimation(
                                        .easeOut(duration: 0.2)
                                    ) {
                                        game.inspectedTeammate = nil
                                    }
                                }
                                .zIndex(15)
                                .transition(.opacity)
                            }

                            // MARK: - Pause Overlay

                            if isPaused && !game.isGameOver {
                                pauseOverlay(compact: compact)
                                    .zIndex(20)
                            }
                        }
                        .overlayPreferenceValue(TheftAnchors.self) { anchors in
                            GeometryReader { proxy in
                                if !game.isResolving && !game.isGameOver {
                                    ForEach(game.pendingThefts) { theft in
                                        if let hand = anchors[.hand(theft.card)], let panel = anchors[.panel(theft.id)] {
                                            BoardGhostFlight(card: theft.card, hand: proxy[hand], panel: proxy[panel]) {
                                                game.finishGhostTheft(theft.id)
                                            }
                                        }
                                    }
                                }
                            }
                            .allowsHitTesting(false)
                        }
                        .background {
                            ZStack {
                                backgroundTan

                                Image("gameboardbg")
                                    .resizable()
                                    .scaledToFill()
                            }
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                        }
        }
        .foregroundStyle(darkBrown)
        .environment(\.colorScheme, .light)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)

        // MARK: - Profile Sheet

        .sheet(
            isPresented: $showProfile,
            onDismiss: {
                loadAvatar()
            }
        ) {
            PlayerProfileView()
        }

        // MARK: - Settings Sheet

        .sheet(isPresented: $showSettings) {
            SettingsView()
        }

        // MARK: - How to Play Sheet

        .sheet(isPresented: $showHowToPlay) {
            BattleHowToPlayView()
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

    // MARK: - Restart Battle

    // Continue remains inside GameBoardView.
    // It does not dismiss the view or reset the app navigation.

    private func restartBattle() {
        isPaused = false
        game.inspectedTeammate = nil
        game.resetGame()
    }

    // MARK: - Top Bar

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
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    lightTan.opacity(0.92),
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .stroke(darkBrown, lineWidth: 1.5)
                }

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
        }

    // MARK: - Portrait Battle

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
                148,
                max(
                    114,
                    availableHeight * 0.19
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
                128,
                max(
                    92,
                    availableHeight * 0.36
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

                    ForEach(game.teammates) { teammate in

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
                in: RoundedRectangle(cornerRadius: 12)
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

private func healerHand(
            height: CGFloat,
            availableWidth: CGFloat
        ) -> some View {

            let cardHeight = max(
                76,
                height - 14
            )
            let sideFootprint = height * 0.55
            return HStack(spacing: 8) {
                
                Image("healer card")
                    .resizable()
                    .scaledToFit()
                    .frame(height: height)
                    .scaleEffect(1.2)
                    .offset(x: 2, y: -4)
                    .zIndex(2) //
                    .allowsHitTesting(false)
                
                GeometryReader { scrollGeo in
                    ScrollView(
                        .horizontal,
                        showsIndicators: false
                    ) {
                        
                        HStack(spacing: 16) {
                            
                            ForEach(
                                displayedHealerCards,
                                id: \.self
                            ) { card in
                                
                                Image(card.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: cardHeight)
                                    .shadow(
                                        color: .black.opacity(0.22),
                                        radius: 4,
                                        y: 2
                                    )
                                    .opacity(game.pendingThefts.contains { $0.card == card } ? 0 : 1)
                                    .anchorPreference(key: TheftAnchors.self, value: .bounds) {
                                        [.hand(card): $0]
                                    }
                                    .draggable(card.rawValue)
                                    .accessibilityLabel(
                                        card.rawValue
                                    )
                            }
                        }
                        .frame(
                            minWidth: scrollGeo.size.width,
                            minHeight: height,
                            alignment: .center
                        )
                    }
                }
                Color.clear
                                .frame(width: sideFootprint, height: height)
                                .allowsHitTesting(false)
            }
            .padding(.horizontal, 16)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .frame(height: height)
            .background {
                Image("healertray")
                    .resizable()
                    .padding(.vertical, -height * 0.34)
                    .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .dropDestination(for: String.self) { items, _ in

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

    // MARK: - Begin Encounter

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
                .frame(maxWidth: .infinity)
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

                    }
                    .foregroundStyle(darkBrown)
                    .padding(compact ? 15 : 22)
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

// MARK: - Move Inspect Overlay

// Uses IdiotMoveCardView from TeammateCardView.swift.
// Do not define IdiotMoveCardView again in this file.

struct MoveInspectOverlayView: View {

    @ObservedObject var teammate: Teammate
    let onDismiss: () -> Void

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

            ZStack {

                Color.black.opacity(0.65)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onDismiss()
                    }

                VStack(spacing: 12) {

                    // MARK: - Teammate Header

                    HStack(spacing: 8) {

                        Image(teammate.headImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: 30,
                                height: 30
                            )

                        Text(
                            "\(teammate.name)'s Possible Moves"
                        )
                        .font(
                            .system(
                                size: 16,
                                weight: .black,
                                design: .serif
                            )
                        )
                        .foregroundStyle(darkBrown)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        cardTan,
                        in: Capsule()
                    )
                    .overlay {
                        Capsule()
                            .stroke(
                                darkBrown,
                                lineWidth: 2
                            )
                    }

                    // MARK: - Possible Move Cards
                    // Reuse the illustrated cards from TeammateCardView.

                    HStack(spacing: 16) {

                        IdiotMoveCardView(
                            card: teammate.optionA
                        )
                        .shadow(
                            color: .black.opacity(0.35),
                            radius: 8,
                            y: 4
                        )

                        IdiotMoveCardView(
                            card: teammate.optionB
                        )
                        .shadow(
                            color: .black.opacity(0.35),
                            radius: 8,
                            y: 4
                        )
                    }
                    .frame(
                        maxWidth: min(
                            460,
                            geometry.size.width - 32
                        ),
                        maxHeight: min(
                            280,
                            geometry.size.height * 0.62
                        )
                    )
                    .onTapGesture {}

                    Text("Tap outside to close")
                        .font(.caption.bold())
                        .foregroundStyle(
                            Color.white.opacity(0.9)
                        )
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Color.black.opacity(0.45),
                            in: Capsule()
                        )
                }
                .padding()
            }
        }
    }
}

// MARK: - How to Play

private struct BattleHowToPlayView: View {

    @Environment(\.dismiss)
    private var dismiss

    private let backgroundTan = Color(
        red: 252.0 / 255,
        green: 220.0 / 255,
        blue: 187.0 / 255
    )

    private let paper = Color(
        red: 1.0,
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

                        // MARK: - Header

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

                                Image(systemName: "swords")

                                Rectangle()
                                    .fill(outline)
                                    .frame(height: 1)
                            }
                        }

                        // MARK: - Instructions

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

                        // MARK: - Dismiss Instructions

                        Button {
                            dismiss()
                        } label: {

                            Text("Got It")
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
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
                    .frame(maxWidth: .infinity)
                }
                .frame(maxHeight: geometry.size.height)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(backgroundTan)
    }

    // MARK: - Rule Card

    private func ruleCard(
        _ number: String,
        _ text: String,
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

// MARK: - Game Over Overlay

// Displays one Continue button for both victory and defeat.

struct GameOverOverlayView: View {

    let didWin: Bool
    let onContinue: () -> Void

    private let darkBrown = Color(
        red: 0.35,
        green: 0.23,
        blue: 0.18
    )

    private let paper = Color(
        red: 1.0,
        green: 243.0 / 255,
        blue: 228.0 / 255
    )

    private let borderBrown = Color(
        red: 0.55,
        green: 0.39,
        blue: 0.29
    )

    private let victoryGreen = Color(
        red: 0.15,
        green: 0.40,
        blue: 0.19
    )

    private let defeatRed = Color(
        red: 0.65,
        green: 0.16,
        blue: 0.13
    )

    var body: some View {

        GeometryReader { geometry in

            let compact =
                geometry.size.height < 410

            ZStack {

                Color.black.opacity(0.60)
                    .ignoresSafeArea()

                ScrollView(
                    .vertical,
                    showsIndicators: false
                ) {

                    VStack(
                        spacing: compact ? 12 : 18
                    ) {

                        // MARK: - Result Icon

                        if didWin {

                            Image(systemName: "crown.fill")
                                .font(
                                    .system(
                                        size: compact ? 32 : 46
                                    )
                                )
                                .foregroundStyle(victoryGreen)

                        } else {

                            Image("ghost")
                                .resizable()
                                .scaledToFit()
                                .frame(
                                    height: compact ? 48 : 68
                                )
                        }

                        // MARK: - Result Title

                        Text(
                            didWin ? "Victory!" : "Defeat!"
                        )
                        .font(
                            .system(
                                size: compact ? 28 : 36,
                                weight: .black,
                                design: .serif
                            )
                        )
                        .foregroundStyle(
                            didWin
                                ? victoryGreen
                                : defeatRed
                        )

                        // MARK: - Result Description

                        Text(
                            didWin
                                ? "Bonk has been defeated! Somehow, you kept the idiots alive."
                                : "Too many idiots became ghosts. Better luck keeping them out of trouble next time!"
                        )
                        .font(
                            .system(
                                size: compact ? 13 : 15,
                                weight: .medium,
                                design: .serif
                            )
                        )
                        .foregroundStyle(darkBrown)
                        .multilineTextAlignment(.center)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                        .padding(.horizontal, 8)

                        // MARK: - Continue Button

                        Button(action: onContinue) {

                            HStack(spacing: 10) {

                                Text("Continue")

                                Image(
                                    systemName: "arrow.right"
                                )
                            }
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(
                                height: compact ? 42 : 48
                            )
                            .background(
                                darkBrown,
                                in: Capsule()
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(
                            "Continue to battle setup"
                        )
                        .padding(.top, 4)
                    }
                    .padding(
                        compact ? 18 : 26
                    )
                    .frame(maxWidth: 400)
                    .background(
                        paper,
                        in: RoundedRectangle(
                            cornerRadius: 22
                        )
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: 22
                        )
                        .stroke(
                            borderBrown,
                            lineWidth: 2
                        )
                    }
                    .shadow(
                        color: .black.opacity(0.25),
                        radius: 16,
                        y: 8
                    )
                    .padding(16)
                    .frame(maxWidth: .infinity)
                }
                .frame(maxHeight: geometry.size.height)
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


enum TheftAnchor: Hashable {
    case hand(HealerCard)
    case panel(UUID)
}

struct TheftAnchors: PreferenceKey {
    static var defaultValue: [TheftAnchor: Anchor<CGRect>] { [:] }
    static func reduce(value: inout [TheftAnchor: Anchor<CGRect>], nextValue: () -> [TheftAnchor: Anchor<CGRect>]) {
        value.merge(nextValue()) { _, new in new }
    }
}

private struct BoardGhostFlight: View {
    let card: HealerCard
    let hand: CGRect
    let panel: CGRect
    let finish: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appears = false
    @State private var grips = false
    @State private var twinkles = false
    @State private var lands = false

    var body: some View {
        ZStack {
            Image(card.imageName)
                .resizable().scaledToFit()
                .frame(width: lands ? 38 : hand.width, height: lands ? 50 : hand.height)
                .rotationEffect(.degrees(lands ? -8 : 0))
                .grayscale(lands ? 1 : 0)
                .opacity(lands ? 0.48 : 1)
                .position(x: lands ? panel.midX : hand.midX, y: lands ? panel.midY + 17 : hand.midY)
            Image("ghost")
                .resizable().scaledToFit().frame(width: 102)
                .scaleEffect(appears || reduceMotion ? 1 : 0.8)
                .opacity(appears ? 1 : 0)
                .position(x: lands ? panel.midX : hand.midX - (grips ? 17 : 35),
                          y: lands ? panel.midY - 12 : hand.midY - (grips ? 18 : 38))
            Image(systemName: "sparkle")
                .font(.title2.bold()).foregroundStyle(.yellow).shadow(color: .brown, radius: 1)
                .opacity(twinkles ? 1 : 0)
                .position(x: hand.midX + 4, y: hand.midY - 40)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Ghost stealing \(card.rawValue)")
        .task {
            do {
                try await Task.sleep(for: .milliseconds(260))
                withAnimation(.easeOut(duration: 0.35)) { appears = true }
                try await Task.sleep(for: .milliseconds(350))
                withAnimation(.easeOut(duration: 0.12)) { twinkles = true }
                try await Task.sleep(for: .milliseconds(180))
                withAnimation(.easeInOut(duration: 0.20)) {
                    twinkles = false
                    grips = true
                }
                try await Task.sleep(for: .milliseconds(270))
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.85)) { lands = true }
                try await Task.sleep(for: .milliseconds(900))
                finish()
            } catch { } // Leaving the board cancels this presentation.
        }
    }
}
