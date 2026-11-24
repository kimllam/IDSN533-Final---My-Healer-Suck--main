
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
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var appRoute: AppRouteState
    @AppStorage("entryMode") private var entryMode = ""

    private var isRegisteredPlayer: Bool {
        entryMode == "account" && auth.isLoggedIn && auth.isEmailVerified
    }

    // MARK: - Profile

    @State private var avatarChoice = "healer card"

    private var avatarScope: String {
        isRegisteredPlayer ? (auth.userID ?? "unknown") : "guest"
    }

    @State private var customAvatar: UIImage?
    @State private var showProfile = false

    // MARK: - Pause Menu

    @State private var isPaused = false
    @State private var showExitConfirmation = false
    @State private var showSettings = false
    @State private var showHowToPlay = false
    @State private var showGuideOptions = false
    @State private var pendingGuideAction: BattleGuideAction?

    private enum BattleGuideAction {
        case replayTutorial
        case reference
    }

    @State private var showFirstTimeTutorial = false
    @State private var showStoryIntro = false

    // Guests retain automatic story onboarding.
    // Registered accounts enter gameplay without automatic onboarding.
    private var storyIntroKey: String {
        "hasSeenGameStory.v1.\(avatarScope)"
    }

    private var shouldShowStory: Bool {
        !isRegisteredPlayer
    }
    @State private var selectedCardHelp: HealerCard?
    // The tutorial completion flag is isolated for each identity.
    private var tutorialKey: String {
        "hasCompletedBattleTutorial.v2.\(avatarScope)"
    }
    private var hasCompletedTutorial: Bool {
        UserDefaults.standard.bool(forKey: tutorialKey)
    }
    @State private var knownAchievements: Set<BattleAchievement> = []
    @State private var newAchievement: BattleAchievement?
    @State private var pendingAchievements: [BattleAchievement] = []

    // Preserve the counters before each new battle for result animation.
    @State private var previousBattleCount = 0
    @State private var previousVictoryCount = 0
    @State private var previousDefeatCount = 0
    @State private var recordUpdate: BattleRecordUpdate?
    @State private var showBattleResults = false


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

                            if game.isGameOver && showBattleResults {
                                GameOverOverlayView(
                                    didWin: game.didPlayerWin,
                                    recordUpdate: recordUpdate,
                                    onContinue: {
                                        restartBattle()
                                    }
                                )
                                .zIndex(10)
                            }

                            // MARK: - Achievement Notification
                            if let achievement = newAchievement {
                                achievementToast(achievement)
                                    .zIndex(40)
                                    .transition(.move(edge: .top).combined(with: .opacity))
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
            HowToPlaySheetView()
        }
        .sheet(isPresented: $showGuideOptions, onDismiss: {
            // Open the selected destination after the choice sheet closes.
            guard let action = pendingGuideAction else { return }
            pendingGuideAction = nil
            // Present the next sheet after the options sheet has fully closed.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                switch action {
                case .replayTutorial:
                    showFirstTimeTutorial = true
                case .reference:
                    showHowToPlay = true
                }
            }
        }) {
            BattleGuideOptionsView { action in
                switch action {
                case .tutorial: pendingGuideAction = .replayTutorial
                case .cards: pendingGuideAction = .reference
                }
                showGuideOptions = false
            }
        }
        .alert(
            selectedCardHelp?.rawValue ?? "Card Guide",
            isPresented: Binding(
                get: { selectedCardHelp != nil },
                set: { if !$0 { selectedCardHelp = nil } }
            )
        ) {
            Button("Got It", role: .cancel) { selectedCardHelp = nil }
            Button("Full Card Guide") {
                selectedCardHelp = nil
                showHowToPlay = true
            }
        } message: {
            Text(cardHelpDescription(selectedCardHelp))
        }
        .fullScreenCover(isPresented: $showStoryIntro, onDismiss: {
            // The account onboarding flag belongs only to the current UID.
            if isRegisteredPlayer {
                UserDefaults.standard.set(true, forKey: storyIntroKey)
            }
            // A story cover and a tutorial sheet cannot transition at once.
            // Guests always get the tutorial after the story, even if an old
            // shared UserDefaults flag says the tutorial was completed.
            let needsTutorial = !isRegisteredPlayer
            if needsTutorial {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                    guard !showStoryIntro else { return }
                    showFirstTimeTutorial = true
                }
            }
        }) {
            GameStoryIntroView()
        }
        .sheet(isPresented: $showFirstTimeTutorial) {
            GameTutorialView {
                // Record completion only after the final training step.
                // Guests never write completion into an account's storage.
                if isRegisteredPlayer {
                    UserDefaults.standard.set(true, forKey: tutorialKey)
                }
            }
        }

        // MARK: - Exit Confirmation

        .alert("Exit to Main Menu?", isPresented: $showExitConfirmation) {
            Button("Keep Playing", role: .cancel) {}
            Button("Exit Battle", role: .destructive) {
                exitBattleToMainMenu()
            }
        } message: {
            Text("Your current unfinished battle will be discarded. Your account and previously saved results will stay intact.")
        }

        // MARK: - Lifecycle

        .onAppear {
            GameRecordStore.shared.beginBattleSession()
            GameRecordStore.shared.refreshForCurrentAccount()
            captureStartingRecordCounts()
            loadAvatar()
            if isRegisteredPlayer {
                GameRecordStore.shared.refreshForCurrentAccount()
                knownAchievements = Set(BattleAchievement.allCases.filter {
                    GameRecordStore.shared.isUnlocked($0)
                })
            } else {
                knownAchievements = []
            }
            if isRegisteredPlayer {
                // Skip automatic onboarding when a registered account enters.
                // Manual tutorials remain available through the help menu.
                showStoryIntro = false
                showFirstTimeTutorial = false
            } else if shouldShowStory {
                // Preserve the guest story and tutorial flow.
                showStoryIntro = true
            }
        }

        .onChange(of: avatarChoice) { _, _ in
            loadAvatar()
        }

        .onChange(of: game.isGameOver) { _, ended in
            guard ended else { return }
            isPaused = false
            showBattleResults = false

            // GameManager records the result immediately after setting isGameOver.
            // The next main-actor turn sees the completed persistence operation.
            Task { @MainActor in
                guard game.isGameOver else { return }
                GameRecordStore.shared.refreshForCurrentAccount()

                if isRegisteredPlayer {
                    let store = GameRecordStore.shared
                    let latestCount = store.gamesPlayed
                    let latestVictories = store.victories
                    let latestDefeats = store.defeats

                    // Show an account counter animation only after a new saved record.
                    if latestCount > previousBattleCount {
                        recordUpdate = BattleRecordUpdate(
                            beforeGames: previousBattleCount,
                            afterGames: latestCount,
                            beforeVictories: previousVictoryCount,
                            afterVictories: latestVictories,
                            beforeDefeats: previousDefeatCount,
                            afterDefeats: latestDefeats
                        )
                    } else {
                        recordUpdate = nil
                    }

                    let unlocked = BattleAchievement.allCases.filter {
                        store.isUnlocked($0) && !knownAchievements.contains($0)
                    }
                    knownAchievements.formUnion(unlocked)
                    pendingAchievements = unlocked
                    if unlocked.isEmpty {
                        showBattleResults = true
                    } else {
                        showNextAchievement()
                    }
                } else {
                    // A guest has no account totals or achievement animations.
                    recordUpdate = nil
                    pendingAchievements.removeAll()
                    showBattleResults = true
                }
            }
        }
    }

    // MARK: - Achievement Toast

    private func achievementToast(_ achievement: BattleAchievement) -> some View {
        ZStack {
            Color.black.opacity(0.64)
                .ignoresSafeArea()

            GeometryReader { geometry in
                let compact = geometry.size.height < 420

                VStack(spacing: compact ? 8 : 13) {
                    ZStack {
                        Circle()
                            .fill(Color.yellow.opacity(0.22))
                            .frame(width: compact ? 94 : 130, height: compact ? 94 : 130)
                            .blur(radius: 15)
                        Image(systemName: "sparkles")
                            .font(.system(size: compact ? 76 : 110))
                            .foregroundStyle(Color.orange.opacity(0.55))
                            .symbolEffect(.pulse, options: .repeating)
                        Image(systemName: achievement.icon)
                            .font(.system(size: compact ? 37 : 48, weight: .bold))
                            .foregroundStyle(Color(red: 0.55, green: 0.32, blue: 0.12))
                            .padding(compact ? 17 : 22)
                            .background(lightTan, in: Circle())
                            .overlay(Circle().stroke(darkBrown, lineWidth: 2))
                            .symbolEffect(.bounce, options: .nonRepeating)
                    }

                    Text("ACHIEVEMENT UNLOCKED!")
                        .font(.system(size: compact ? 12 : 15, weight: .black, design: .rounded))
                        .tracking(2)
                    Text(achievement.title)
                        .font(.system(size: compact ? 24 : 30, weight: .black, design: .serif))
                    Text(achievement.detail)
                        .font(.system(size: compact ? 12 : 14, design: .serif))
                        .multilineTextAlignment(.center)
                    Button {
                        withAnimation(.spring(response: 0.36)) {
                            newAchievement = nil
                        }
                        if pendingAchievements.isEmpty {
                            showBattleResults = true
                        } else {
                            showNextAchievement()
                        }
                    } label: {
                        Text(pendingAchievements.isEmpty ? "View Battle Results" : "Next Achievement")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: compact ? 36 : 43)
                            .background(darkBrown, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .foregroundStyle(darkBrown)
                .padding(.horizontal, compact ? 25 : 32)
                .padding(.vertical, compact ? 13 : 23)
                .frame(maxWidth: 440)
                .background(paper, in: RoundedRectangle(cornerRadius: 24))
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(darkBrown, lineWidth: 2)
                }
                .shadow(color: .black.opacity(0.25), radius: 18, y: 7)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.85)))
        .zIndex(40)
    }

    private func captureStartingRecordCounts() {
        let store = GameRecordStore.shared
        if isRegisteredPlayer {
            previousBattleCount = store.gamesPlayed
            previousVictoryCount = store.victories
            previousDefeatCount = store.defeats
        } else {
            previousBattleCount = 0
            previousVictoryCount = 0
            previousDefeatCount = 0
        }
        recordUpdate = nil
        showBattleResults = false
    }

    private func showNextAchievement() {
        guard newAchievement == nil, !pendingAchievements.isEmpty else { return }
        withAnimation {
            newAchievement = pendingAchievements.removeFirst()
        }
    }

    // MARK: - Exit Battle

    private func exitBattleToMainMenu() {
        isPaused = false
        showExitConfirmation = false
        game.inspectedTeammate = nil
        GameRecordStore.shared.endBattleSession()
        game.resetGame()
        // Keep entryMode unchanged so guest/account identity is preserved.
        appRoute.returnToLaunchScreen()
    }

    // MARK: - Restart Battle

    // Continue remains inside GameBoardView.
    // It does not dismiss the view or reset the app navigation.

    private func restartBattle() {
        newAchievement = nil
        pendingAchievements = []
        recordUpdate = nil
        showBattleResults = false
        isPaused = false
        game.inspectedTeammate = nil
        GameRecordStore.shared.endBattleSession()
        game.resetGame()
        GameRecordStore.shared.beginBattleSession()
        GameRecordStore.shared.refreshForCurrentAccount()
        captureStartingRecordCounts()
    }

    // MARK: - Healer Card Descriptions

    private func cardHelpDescription(_ card: HealerCard?) -> String {
        guard let card else { return "Long press a card for details, or drag it onto a teammate to play." }
        switch card {
        case .heal:
            return "Heal (+1 HP): Restore one health point to the teammate who receives this card. Drag the card onto a teammate to assign it."
        case .reverse:
            return "Reverse: Redirect incoming damage according to the game's Reverse rules. Drag the card to assign it."
        case .doNothing:
            return "Do Nothing: Assign no healing or damage redirection for this action. Drag the card to a teammate to choose this option."
        }
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

                Text("Hold a card (0.5s) or tap its ? for details")
                    .font(.system(size: compact ? 10 : 12, weight: .medium, design: .rounded))
                    .foregroundStyle(darkBrown)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

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

                // MARK: - Quick Help Button
                Button {
                    showGuideOptions = true
                } label: {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(darkBrown)
                        .frame(width: 44, height: 44)
                        .background(lightTan, in: Circle())
                        .overlay { Circle().stroke(darkBrown, lineWidth: 1.5) }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("How to Play and Card Guide")

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

            ScrollViewReader { scroll in
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
                            .id(teammate.id)
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
                .task(id: game.pendingThefts.first?.id) {
                    if let theft = game.pendingThefts.first {
                        scroll.scrollTo(theft.id, anchor: .center)
                    }
                }
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
                    ScrollViewReader { scroll in
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
                                        .shadow(color: .black.opacity(0.22), radius: 4, y: 2)
                                        .opacity(game.pendingThefts.contains { $0.card == card } ? 0 : 1)
                                        .anchorPreference(key: TheftAnchors.self, value: .bounds) {
                                            [.hand(card): $0]
                                        }
                                        .id(card)
                                        .draggable(card.rawValue)
                                        .simultaneousGesture(
                                            LongPressGesture(minimumDuration: 0.5)
                                                .onEnded { _ in
                                                    selectedCardHelp = card
                                                }
                                        )
                                        .overlay(alignment: .topTrailing) {
                                            // A tappable fallback is reliable when iOS drag competes with long press.
                                            Button {
                                                selectedCardHelp = card
                                            } label: {
                                                Image(systemName: "questionmark.circle.fill")
                                                    .font(.system(size: 19, weight: .bold))
                                                    .foregroundStyle(darkBrown)
                                                    .background(paper, in: Circle())
                                            }
                                            .buttonStyle(.plain)
                                            .padding(2)
                                            .accessibilityLabel("Explain \(card.rawValue) card")
                                        }
                                        .accessibilityLabel(card.rawValue)
                                        .accessibilityHint("Hold or tap question mark for details. Drag onto a teammate to play.")
                                }
                            }
                            .frame(
                                minWidth: scrollGeo.size.width,
                                minHeight: height,
                                alignment: .center
                            )
                        }
                        .task(id: game.pendingThefts.first?.card) {
                            if let theft = game.pendingThefts.first {
                                scroll.scrollTo(theft.card, anchor: .center)
                            }
                        }
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

                        pauseMenuButton(
                            "Exit to Main Menu",
                            icon: "house.fill",
                            compact: compact
                        ) {
                            showExitConfirmation = true
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
        avatarChoice = UserDefaults.standard.string(
            forKey: "playerAvatarChoice.\(avatarScope)"
        ) ?? "healer card"
        customAvatar = AvatarFile.load(for: avatarScope)
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

// Account totals animate separately from first-time achievement rewards.
struct BattleRecordUpdate: Equatable {
    let beforeGames: Int
    let afterGames: Int
    let beforeVictories: Int
    let afterVictories: Int
    let beforeDefeats: Int
    let afterDefeats: Int
}

// Displays only Play Again for both victory and defeat.
struct GameOverOverlayView: View {

    let didWin: Bool
    let recordUpdate: BattleRecordUpdate?
    let onContinue: () -> Void

    @State private var shownGames = 0
    @State private var shownVictories = 0
    @State private var shownDefeats = 0


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

    private func recordStat(_ title: String, value: Int) -> some View {
        VStack(spacing: 3) {
            Text("\(value)")
                .font(.system(size: 23, weight: .black, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(darkBrown)
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(darkBrown.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
    }

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

                        // MARK: - Saved Account Record

                        if let recordUpdate {
                            VStack(spacing: compact ? 6 : 10) {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(victoryGreen)
                                    Text("BATTLE RECORD UPDATED")
                                        .font(.system(size: compact ? 10 : 12, weight: .black, design: .rounded))
                                        .tracking(1.1)
                                }

                                HStack(spacing: 8) {
                                    recordStat("Battles", value: shownGames)
                                    recordStat("Wins", value: shownVictories)
                                    recordStat("Losses", value: shownDefeats)
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Updated totals: \(recordUpdate.afterGames) battles, \(recordUpdate.afterVictories) wins, \(recordUpdate.afterDefeats) losses")
                            }
                            .padding(compact ? 9 : 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                Color(red: 0.98, green: 0.89, blue: 0.78),
                                in: RoundedRectangle(cornerRadius: 13)
                            )
                            .task(id: recordUpdate) {
                                shownGames = recordUpdate.beforeGames
                                shownVictories = recordUpdate.beforeVictories
                                shownDefeats = recordUpdate.beforeDefeats

                                try? await Task.sleep(for: .milliseconds(180))
                                guard !Task.isCancelled else { return }
                                withAnimation(.easeOut(duration: 0.8)) {
                                    shownGames = recordUpdate.afterGames
                                    shownVictories = recordUpdate.afterVictories
                                    shownDefeats = recordUpdate.afterDefeats
                                }
                            }
                        }

                        // MARK: - Continue Button

                        Button(action: onContinue) {

                            HStack(spacing: 10) {

                                Text("Play Again")

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
                            "Start another battle"
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



