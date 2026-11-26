//
//  GameBoardView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/11/26.
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

    // MARK: - Pause & Guides

    @State private var isPaused = false
    @State private var pendingPauseAction: PauseMenuAction?
    @State private var showExitConfirmation = false
    @State private var showSettings = false
    @State private var showHowToPlay = false
    @State private var showGuideOptions = false
    @State private var pendingGuideAction: BattleGuideAction?

    private enum PauseMenuAction {
        case profile
        case settings
        case howToPlay
        case exit
    }

    private enum BattleGuideAction {
        case replayTutorial
        case reference
    }

    @State private var showFirstTimeTutorial = false
    @State private var selectedCardHelp: HealerCard?

    // The tutorial completion flag is isolated for each identity.
    private var tutorialKey: String {
        "hasCompletedBattleTutorial.v2.\(avatarScope)"
    }

    // MARK: - Battle Records & Achievements

    @State private var knownAchievements: Set<BattleAchievement> = []
    @State private var newAchievement: BattleAchievement?
    @State private var pendingAchievements: [BattleAchievement] = []

    // Preserve the counters before each new battle for result animation.
    @State private var previousBattleCount = 0
    @State private var previousVictoryCount = 0
    @State private var previousDefeatCount = 0
    @State private var recordUpdate: BattleRecordUpdate?
    @State private var showBattleResults = false

    private var displayedHealerCards: [HealerCard] {
        guard !game.pendingThefts.isEmpty else { return game.availableCards }
        return HealerCard.allCases.filter { card in
            game.availableCards.contains(card) || game.pendingThefts.contains { $0.card == card }
        }
    }

    // MARK: - Main View

    var body: some View {
        GeometryReader { geometry in
            let portrait = geometry.size.width < geometry.size.height
            let compact = geometry.size.height < 410

            ZStack {
                VStack(spacing: 0) {
                    if !game.isGameOver {
                        topBar(compact: compact)
                    }

                    if game.isResolving {
                        EncounterResolutionView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .allowsHitTesting(!isPaused)
                    } else if portrait {
                        portraitBattleBoard(size: geometry.size)
                            .allowsHitTesting(!isPaused && game.pendingThefts.isEmpty)
                    } else {
                        landscapeBattleBoard(size: geometry.size, compact: compact)
                            .allowsHitTesting(!isPaused && game.pendingThefts.isEmpty)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

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

                if let achievement = newAchievement {
                    AchievementToastView(
                        achievement: achievement,
                        hasMoreAchievements: !pendingAchievements.isEmpty
                    ) {
                        withAnimation(.spring(response: 0.36)) {
                            newAchievement = nil
                        }
                        if pendingAchievements.isEmpty {
                            showBattleResults = true
                        } else {
                            showNextAchievement()
                        }
                    }
                    .zIndex(40)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                if let teammate = game.inspectedTeammate,
                   !game.isResolving,
                   !game.isGameOver {
                    MoveInspectOverlayView(teammate: teammate) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            game.inspectedTeammate = nil
                        }
                    }
                    .zIndex(15)
                    .transition(.opacity)
                }

                if isPaused && !game.isGameOver {
                    PauseOverlayView(
                        compact: compact,
                        onClose: {
                            withAnimation {
                                pendingPauseAction = nil
                                isPaused = false
                            }
                        },
                        onResume: {
                            withAnimation {
                                pendingPauseAction = nil
                                isPaused = false
                            }
                        },
                        onOpenProfile: {
                            triggerPauseAction(.profile)
                        },
                        onOpenSettings: {
                            triggerPauseAction(.settings)
                        },
                        onOpenHowToPlay: {
                            triggerPauseAction(.howToPlay)
                        },
                        onRequestExit: {
                            triggerPauseAction(.exit)
                        }
                    )
                    .zIndex(20)
                }
            }
            .overlayPreferenceValue(TheftAnchors.self) { anchors in
                GeometryReader { proxy in
                    if !game.isResolving && !game.isGameOver {
                        ForEach(game.pendingThefts) { theft in
                            if let hand = anchors[.hand(theft.card)],
                               let panel = anchors[.panel(theft.id)] {
                                BoardGhostFlight(
                                    card: theft.card,
                                    hand: proxy[hand],
                                    panel: proxy[panel]
                                ) {
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
                    AppTheme.backgroundTan

                    Image("gameboardbg")
                        .resizable()
                        .scaledToFill()
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
        .foregroundStyle(AppTheme.darkBrown)
        .environment(\.colorScheme, .light)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showProfile, onDismiss: { loadAvatar() }) {
            PlayerProfileView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showHowToPlay) {
            HowToPlaySheetView()
        }
        .sheet(isPresented: $showGuideOptions, onDismiss: {
            guard let action = pendingGuideAction else { return }
            pendingGuideAction = nil
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
        .sheet(isPresented: $showFirstTimeTutorial) {
            GameTutorialView {
                if isRegisteredPlayer {
                    UserDefaults.standard.set(true, forKey: tutorialKey)
                }
            }
        }
        .alert("Returning Home?", isPresented: $showExitConfirmation) {
            Button("Keep Playing", role: .cancel) {}
            Button("Exit Battle", role: .destructive) {
                exitBattleToMainMenu()
            }
        } message: {
            Text("Your current battle will be discarded.")
        }
        .onAppear {
            AudioManager.shared.playAmbient(named: "cave_ambient")

            GameRecordStore.shared.beginBattleSession()
            GameRecordStore.shared.refreshForCurrentAccount()
            captureStartingRecordCounts()
            loadAvatar()

            if isRegisteredPlayer {
                knownAchievements = Set(BattleAchievement.allCases.filter {
                    GameRecordStore.shared.isUnlocked($0)
                })
            } else {
                knownAchievements = []
            }

            showFirstTimeTutorial = true
        }
        .onDisappear {
            AudioManager.shared.stopAmbient()
        }
        .onChange(of: avatarChoice) { _, _ in
            loadAvatar()
        }
        .onChange(of: game.isGameOver) { _, ended in
            guard ended else { return }
            isPaused = false
            pendingPauseAction = nil
            showBattleResults = false

            Task { @MainActor in
                guard game.isGameOver else { return }
                GameRecordStore.shared.refreshForCurrentAccount()

                if isRegisteredPlayer {
                    let store = GameRecordStore.shared
                    let latestCount = store.gamesPlayed
                    let latestVictories = store.victories
                    let latestDefeats = store.defeats

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
                    recordUpdate = nil
                    pendingAchievements.removeAll()
                    showBattleResults = true
                }
            }
        }
    }

    // MARK: - Pause Menu Dispatch

    private func triggerPauseAction(_ action: PauseMenuAction) {
        pendingPauseAction = action
        withAnimation(.easeOut(duration: 0.15)) {
            isPaused = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            guard let nextAction = pendingPauseAction else { return }
            pendingPauseAction = nil
            switch nextAction {
            case .profile:
                loadAvatar()
                showProfile = true
            case .settings:
                showSettings = true
            case .howToPlay:
                showHowToPlay = true
            case .exit:
                showExitConfirmation = true
            }
        }
    }

    // MARK: - Records, Achievements & Session Flow

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
        AudioManager.shared.playEffect(named: "achievement")
    }

    private func exitBattleToMainMenu() {
        isPaused = false
        pendingPauseAction = nil
        showExitConfirmation = false
        game.inspectedTeammate = nil
        GameRecordStore.shared.endBattleSession()
        game.resetGame()
        appRoute.returnToLaunchScreen()
    }

    private func restartBattle() {
        newAchievement = nil
        pendingAchievements = []
        recordUpdate = nil
        showBattleResults = false
        isPaused = false
        pendingPauseAction = nil
        game.inspectedTeammate = nil
        GameRecordStore.shared.endBattleSession()
        game.resetGame()
        GameRecordStore.shared.beginBattleSession()
        GameRecordStore.shared.refreshForCurrentAccount()
        captureStartingRecordCounts()
    }

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

    private func topBar(compact: Bool) -> some View {
        HStack(spacing: 10) {
            Text(game.isResolving ? "Encounter" : "Assign Your Healer Cards")
                .font(.system(size: compact ? 14 : 17, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.darkBrown)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(AppTheme.lightTan.opacity(0.92), in: Capsule())
                .overlay {
                    Capsule().stroke(AppTheme.darkBrown, lineWidth: 1.5)
                }

            Text("Hold a card (0.5s) or tap its ? for details")
                .font(.system(size: compact ? 10 : 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.darkBrown)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 4)

            Button {
                showGuideOptions = true
            } label: {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppTheme.darkBrown)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.lightTan, in: Circle())
                    .overlay { Circle().stroke(AppTheme.darkBrown, lineWidth: 1.5) }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("How to Play and Card Guide")

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPaused = true
                }
            } label: {
                Image(systemName: "pause.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppTheme.darkBrown)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.lightTan, in: Circle())
                    .overlay { Circle().stroke(AppTheme.darkBrown, lineWidth: 1.5) }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Pause Game")
        }
        .padding(.horizontal, 12)
        .frame(height: 56)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Portrait & Landscape Boards

    private func portraitBattleBoard(size: CGSize) -> some View {
        let availableHeight = max(0, size.height - 56)
        let bossHeight: CGFloat = min(150, max(108, availableHeight * 0.19))
        let handHeight: CGFloat = min(148, max(114, availableHeight * 0.19))

        return VStack(spacing: 10) {
            teammatePanel
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 12) {
                bonkWithHP
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                beginEncounterButton(compact: false)
                    .frame(width: min(172, size.width * 0.44))
            }
            .frame(height: bossHeight)

            healerHand(height: handHeight, availableWidth: size.width - 24)
                .frame(height: handHeight)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private func landscapeBattleBoard(size: CGSize, compact: Bool) -> some View {
        let gap: CGFloat = 10
        let usableWidth = max(0, size.width - 24 - gap)
        let bossWidth = min(210, max(135, usableWidth * 0.22))
        let teammateWidth = max(0, usableWidth - bossWidth)
        let availableHeight = max(0, size.height - 56)
        let handHeight = min(128, max(92, availableHeight * 0.36))

        return HStack(spacing: gap) {
            VStack(spacing: 7) {
                teammatePanel
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                healerHand(height: handHeight, availableWidth: teammateWidth)
                    .frame(height: handHeight)
            }
            .frame(width: teammateWidth)

            VStack(spacing: 8) {
                bonkWithHP
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                beginEncounterButton(compact: compact)
            }
            .frame(width: bossWidth)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Boss, Teammates, Hand & Actions

    private var bonkWithHP: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)

            ZStack {
                Image("bonk cave")
                    .resizable()
                    .scaledToFit()
                    .rotationEffect(.degrees(270))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text("\(max(0, game.bonkHP)) / 5 HP")
                    .font(.system(size: min(17, max(11, side * 0.075)), weight: .black, design: .serif))
                    .foregroundStyle(AppTheme.darkBrown)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .offset(y: -side * 0.20)
                    .allowsHitTesting(false)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Bonk, \(max(0, game.bonkHP)) of 5 HP")
    }

    private var teammatePanel: some View {
        GeometryReader { region in
            let outerPadding: CGFloat = 10
            let gap: CGFloat = 8
            let minimumCardWidth: CGFloat = 185

            let innerWidth = max(0, region.size.width - outerPadding * 2)
            let fittingCardWidth = max(0, (innerWidth - gap * 2) / 3)
            let canShowAll = fittingCardWidth >= minimumCardWidth

            let cardWidth = canShowAll
                ? fittingCardWidth
                : min(245, max(205, region.size.width * 0.66))

            let cardHeight = max(0, region.size.height - outerPadding * 2)

            ScrollViewReader { scroll in
                ScrollView(.horizontal, showsIndicators: !canShowAll) {
                    HStack(alignment: .top, spacing: gap) {
                        ForEach(game.teammates) { teammate in
                            TeammateCardView(teammate: teammate)
                                .frame(width: cardWidth, height: cardHeight)
                                .id(teammate.id)
                        }
                    }
                    .padding(outerPadding)
                    .frame(
                        minWidth: region.size.width,
                        alignment: canShowAll ? .center : .leading
                    )
                }
                .task(id: game.pendingThefts.first?.id) {
                    if let theft = game.pendingThefts.first {
                        scroll.scrollTo(theft.id, anchor: .center)
                    }
                }
            }
            .background(AppTheme.lightTan, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.brown, lineWidth: 2)
            }
        }
    }

    private func healerHand(height: CGFloat, availableWidth: CGFloat) -> some View {
        let cardHeight = max(76, height - 14)
        let sideFootprint = height * 0.55

        return HStack(spacing: 8) {
            Image("healer card")
                .resizable()
                .scaledToFit()
                .frame(height: height)
                .scaleEffect(1.2)
                .offset(x: 2, y: -4)
                .zIndex(2)
                .allowsHitTesting(false)

            GeometryReader { scrollGeo in
                ScrollViewReader { scroll in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(displayedHealerCards, id: \.self) { card in
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
                                        Button {
                                            selectedCardHelp = card
                                        } label: {
                                            Image(systemName: "questionmark.circle.fill")
                                                .font(.system(size: 19, weight: .bold))
                                                .foregroundStyle(AppTheme.darkBrown)
                                                .background(AppTheme.paper, in: Circle())
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
        .frame(maxWidth: .infinity, alignment: .leading)
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
                  let healerCard = HealerCard(rawValue: rawCard) else {
                return false
            }

            withAnimation {
                game.returnToHand(card: healerCard)
            }
            return true
        }
    }

    private func beginEncounterButton(compact: Bool) -> some View {
        Button {
            withAnimation {
                game.resolveEncounter()
            }
        } label: {
            Text("Begin Encounter")
                .font(.system(size: compact ? 13 : 15, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: compact ? 42 : 48)
                .background(
                    game.allLivingAssigned && !game.isGameOver
                        ? Color.green
                        : Color.gray,
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                }
        }
        .buttonStyle(.plain)
        .disabled(!game.allLivingAssigned || game.isGameOver)
    }

    // MARK: - Avatar

    private func loadAvatar() {
        avatarChoice = UserDefaults.standard.string(
            forKey: "playerAvatarChoice.\(avatarScope)"
        ) ?? "healer card"
        customAvatar = AvatarFile.load(for: avatarScope)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GameBoardView()
            .environmentObject(GameManager())
            .environmentObject(AuthManager())
            .environmentObject(AppRouteState())
    }
}
