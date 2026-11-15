
//
//  GameBoardView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/11/26.
//

import SwiftUI
import UIKit

struct GameBoardView: View {

    @EnvironmentObject var game: GameManager
    @Environment(\.dismiss) private var dismiss

    // MARK: - Player Profile Integration
    // Added by Jingyi: Player avatar and profile navigation.

    @AppStorage("playerAvatarChoice")
    private var avatarChoice = "healer card"

    @State private var customAvatar: UIImage?
    @State private var showProfile = false

    // MARK: - Pause Menu Integration
    // Added by Jingyi: In-game pause menu and navigation.

    @State private var isPaused = false
    @State private var showSettings = false
    @State private var showHowToPlay = false
    @State private var confirmReturnHome = false

    // MARK: - Existing Game Colors

    private let backgroundTan = Color(
        red: 252 / 255,
        green: 220 / 255,
        blue: 187 / 255
    )

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

    private let paper = Color(
        red: 255 / 255,
        green: 243 / 255,
        blue: 228 / 255
    )

    // MARK: - Main View

    var body: some View {
        ZStack {

            backgroundTan
                .ignoresSafeArea()

            // Existing battle content

            Group {
                if game.isResolving {

                    EncounterResolutionView()
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(
                                    with: .scale(scale: 0.96)
                                ),
                                removal: .opacity
                            )
                        )

                } else {

                    battleBoard
                        .transition(
                            .asymmetric(
                                insertion: .opacity,
                                removal: .scale(
                                    scale: 0.85,
                                    anchor: .top
                                )
                                .combined(with: .opacity)
                            )
                        )
                }
            }
            .allowsHitTesting(!isPaused)

            // Existing game-over screen

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
                .transition(
                    .opacity.combined(
                        with: .scale(scale: 0.9)
                    )
                )
                .zIndex(10)
            }

            // MARK: - Pause Overlay
            // Added by Jingyi: Blocks battle interactions
            // while the pause menu is visible.

            if isPaused && !game.isGameOver {
                pauseOverlay
                    .zIndex(20)
            }
        }

        // MARK: - Battle Shortcuts
        // Added by Jingyi: Profile and Pause buttons.

        .overlay(alignment: .topTrailing) {

            if !isPaused && !game.isGameOver {

                HStack(spacing: 10) {

                    Button {
                        loadAvatar()
                        showProfile = true
                    } label: {
                        playerAvatarButton
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Player Profile")

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
                                    size: 18,
                                    weight: .bold
                                )
                            )
                            .foregroundStyle(darkBrown)
                            .frame(width: 44, height: 44)
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
                .padding(.top, 8)
                .padding(.trailing, 16)
            }
        }

        // MARK: - Navigation
        // Added by Jingyi: Open additional screens
        // without resetting the current battle.

        .sheet(
            isPresented: $showProfile,
            onDismiss: {
                loadAvatar()
            }
        ) {
            PlayerProfileView()
        }

        .sheet(isPresented: $showSettings) {
            SettingsView()
        }

        // MARK: - Redesigned Battle Instructions
        // Updated by Jingyi: Use the dedicated
        // centered instruction screen.

        .sheet(isPresented: $showHowToPlay) {
            BattleHowToPlayView()
        }

        // MARK: - Return Home Confirmation
        // Added by Jingyi: Prevent accidental exits.

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

        .onAppear {
            loadAvatar()
        }

        .onChange(of: avatarChoice) { _, _ in
            loadAvatar()
        }

        .onChange(of: game.isGameOver) { _, gameOver in
            if gameOver {
                isPaused = false
            }
        }
    }

    // MARK: - Existing Battle Board
    // Original card assignment and Bonk logic retained.

    private var battleBoard: some View {
        GeometryReader { geometry in

            HStack(spacing: 0) {

                // LEFT COLUMN:
                // Encounter label, Idiots row and healer cards

                VStack(spacing: 0) {

                    Text("Assign Your Healer Cards")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .padding(.top, 12)

                    Spacer(minLength: 5)

                    // Existing Idiots row

                    VStack {
                        HStack(
                            alignment: .top,
                            spacing: 8
                        ) {
                            ForEach(game.teammates) { teammate in
                                TeammateCardView(
                                    teammate: teammate
                                )
                            }
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(lightTan)
                            .overlay {
                                RoundedRectangle(
                                    cornerRadius: 12
                                )
                                .stroke(
                                    Color.brown,
                                    lineWidth: 2
                                )
                            }
                    )
                    .padding(.horizontal, 10)

                    Spacer(minLength: 4)

                    // Existing healer cards

                    HStack(spacing: 120) {

                        VStack {
                            Image("healer card")
                                .resizable()
                                .scaledToFit()
                                .scaleEffect(2)
                                .offset(x: 64)
                                .frame(
                                    width: 100,
                                    height: 100
                                )
                                .zIndex(-1)
                        }

                        HStack(spacing: 4) {

                            ForEach(
                                game.availableCards,
                                id: \.self
                            ) { card in

                                Image(card.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 120)
                                    .shadow(
                                        color: .black.opacity(0.2),
                                        radius: 8,
                                        y: 1
                                    )
                                    .draggable(card.rawValue)
                            }
                        }
                        .frame(minHeight: 95)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .dropDestination(for: String.self) {
                        items, _ in

                        guard let rawCard = items.first,
                              let healerCard = HealerCard(
                                rawValue: rawCard
                              )
                        else {
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
                    width: geometry.size.width * 0.80
                )

                // RIGHT COLUMN:
                // Existing Bonk section

                VStack(spacing: 20) {

                    VStack(spacing: 5) {
                        Text(
                            "\(max(0, game.bonkHP)) / 5 HP"
                        )
                        .font(.headline)
                        .bold()
                        .foregroundColor(.black)
                        .offset(x: -8, y: 74)
                    }
                    .padding(.top, 30)

                    Image("bonk cave")
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(1.6)
                        .rotationEffect(.degrees(270))
                        .offset(x: -12, y: 24)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity
                        )
                        .layoutPriority(-1)
                        .zIndex(-1)

                    Spacer()

                    VStack(spacing: 10) {

                        Button {
                            withAnimation {
                                game.resolveEncounter()
                            }
                        } label: {
                            Text("Begin Encounter")
                                .font(.headline)
                                .bold()
                                .foregroundColor(.white)
                                .frame(
                                    width: 200,
                                    height: 45
                                )
                                .background(
                                    game.allLivingAssigned &&
                                    !game.isGameOver
                                    ? Color.green
                                    : Color.gray
                                )
                                .cornerRadius(25)
                                .overlay {
                                    RoundedRectangle(
                                        cornerRadius: 25
                                    )
                                    .stroke(
                                        Color.gray.opacity(0.5),
                                        lineWidth: 3
                                    )
                                }
                        }
                        .disabled(
                            !game.allLivingAssigned ||
                            game.isGameOver
                        )
                    }
                    .padding(.bottom, 20)
                }
                .frame(
                    width: geometry.size.width * 0.35
                )
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
    }

    // MARK: - Pause Menu
    // Added by Jingyi: Resume, Settings,
    // How to Play and Return Home.

    private var pauseOverlay: some View {
        ZStack {

            Color.black.opacity(0.56)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {

                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 36))

                    Text("Game Paused")
                        .font(
                            .system(
                                size: 29,
                                weight: .bold,
                                design: .serif
                            )
                        )

                    Text("Even heroes need a break.")
                        .font(
                            .system(
                                size: 14,
                                design: .serif
                            )
                        )
                        .italic()
                        .foregroundStyle(
                            darkBrown.opacity(0.7)
                        )
                        .padding(.bottom, 7)

                    pauseMenuButton(
                        "Resume Game",
                        icon: "play.fill",
                        prominent: true
                    ) {
                        withAnimation(
                            .easeInOut(duration: 0.2)
                        ) {
                            isPaused = false
                        }
                    }

                    pauseMenuButton(
                        "Settings",
                        icon: "gearshape.fill"
                    ) {
                        showSettings = true
                    }

                    pauseMenuButton(
                        "How to Play",
                        icon: "book.closed.fill"
                    ) {
                        showHowToPlay = true
                    }

                    pauseMenuButton(
                        "Return Home",
                        icon: "house.fill"
                    ) {
                        confirmReturnHome = true
                    }
                }
                .foregroundStyle(darkBrown)
                .padding(24)
                .frame(maxWidth: 360)
                .background(
                    paper,
                    in: RoundedRectangle(cornerRadius: 20)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
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
                .padding(20)
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: 530)
        }
    }

    // MARK: - Pause Menu Buttons
    // Added by Jingyi: Reusable button styling.

    private func pauseMenuButton(
        _ title: String,
        icon: String,
        prominent: Bool = false,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {

            HStack(spacing: 12) {

                Image(systemName: icon)
                    .font(.system(size: 17))
                    .frame(width: 24)

                Text(title)
                    .font(
                        .system(
                            size: 16,
                            weight: .semibold
                        )
                    )

                Spacer()

                if !prominent {
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                }
            }
            .foregroundStyle(
                prominent ? Color.white : darkBrown
            )
            .padding(.horizontal, 17)
            .frame(height: 51)
            .background(
                prominent ? darkBrown : backgroundTan,
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
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
    // Added by Jingyi: Displays saved player avatar.

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
        .frame(width: 44, height: 44)
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
    // Added by Jingyi: Uses the same local
    // avatar path as PlayerProfileView.

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

// MARK: - Battle How to Play
// Added by Jingyi: Centered in-game tutorial layout.
// Original gameplay instructions are preserved.

private struct BattleHowToPlayView: View {

    @Environment(\.dismiss)
    private var dismiss

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

                        // Title

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

                        // Original game rules

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

                        // Close button

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
        .presentationDragIndicator(.visible)
    }

    // MARK: - Rule Card
    // Added by Jingyi: Individual numbered rule cards.

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

// MARK: - Existing Game Over Overlay
// Original game result interface retained.

struct GameOverOverlayView: View {

    let didWin: Bool
    let onPlayAgain: () -> Void
    let onReturnHome: () -> Void

    let darkBrown = Color(
        red: 0.35,
        green: 0.23,
        blue: 0.18
    )

    let cardTan = Color(
        red: 0.98,
        green: 0.88,
        blue: 0.74
    )

    var body: some View {
        ZStack {

            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 18) {

                Text(didWin ? "YOU WIN!" : "YOU LOST!")
                    .font(
                        .system(
                            size: 38,
                            weight: .black,
                            design: .serif
                        )
                    )
                    .foregroundColor(
                        didWin ? .green : .red
                    )

                Text(
                    didWin
                    ? "Bonk has been defeated!"
                    : "Two idiots became ghosts!"
                )
                .font(.headline)
                .foregroundColor(darkBrown)

                HStack(spacing: 16) {

                    Button(action: onPlayAgain) {
                        Text("Play Again")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(
                                width: 140,
                                height: 44
                            )
                            .background(Color.green)
                            .cornerRadius(22)
                    }

                    Button(action: onReturnHome) {
                        Text("Return Home")
                            .font(.headline.bold())
                            .foregroundColor(darkBrown)
                            .frame(
                                width: 140,
                                height: 44
                            )
                            .background(.white)
                            .cornerRadius(22)
                            .overlay {
                                RoundedRectangle(
                                    cornerRadius: 22
                                )
                                .stroke(
                                    darkBrown,
                                    lineWidth: 2
                                )
                            }
                    }
                }
                .padding(.top, 6)
            }
            .padding(28)
            .background(cardTan)
            .cornerRadius(20)
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        darkBrown,
                        lineWidth: 3
                    )
            }
            .shadow(radius: 15)
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

