
//
//  HomeView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/11/26.
//  Added by Jingyi: Settings button on the home screen.
//  Updated by Jingyi: Account selection and unified tutorial layout.
//  Updated by Jingyi: Align landscape controls with the artwork title.
//

import SwiftUI

struct HomeView: View {

    @EnvironmentObject var game: GameManager
    @EnvironmentObject private var auth: AuthManager
    @AppStorage("entryMode") private var entryMode = ""

    @State private var showHowToPlay = false
    @State private var showSettings = false

    // MARK: - Colors

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

    private let backgroundTan = Color(
        red: 252.0 / 255,
        green: 220.0 / 255,
        blue: 187.0 / 255
    )

    // MARK: - Main View
    // Artwork and controls share one coordinate space.

    var body: some View {
        GeometryReader { screen in

            let size = screen.size
            let insets = screen.safeAreaInsets
            let isPortrait = size.width < size.height

            ZStack {

                // MARK: - Full-Screen Artwork

                Image("landing")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: size.width,
                        height: size.height
                    )
                    .clipped()
                    .allowsHitTesting(false)

                // MARK: - Controls

                if isPortrait {
                    portraitControls(
                        screen: size,
                        insets: insets
                    )
                } else {
                    landscapeControls(
                        screen: size,
                        insets: insets
                    )
                }
            }
            .frame(
                width: size.width,
                height: size.height
            )
        }
        .ignoresSafeArea()
        .background {
            backgroundTan
                .ignoresSafeArea()
        }
        .toolbar(
            .hidden,
            for: .navigationBar
        )

        // MARK: - Refresh Account Verification

        .task(id: auth.userID) {
            // Restore the current Firebase user without a password.
            if auth.isLoggedIn && !auth.isEmailVerified {
                _ = try? await auth.checkEmailVerification()
            }
        }

        // MARK: - Sheets

        .sheet(isPresented: $showHowToPlay) {
            HowToPlaySheetView()
        }

        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - Title Logo

    private var titleLogo: some View {
        Image("GameTitle")
            .resizable()
            .scaledToFit()
            .allowsHitTesting(false)
            .accessibilityLabel("My Healer Sucks!")
    }

    // MARK: - Portrait Controls

    private func portraitControls(
        screen: CGSize,
        insets: EdgeInsets
    ) -> some View {

        let safeWidth = max(
            0,
            screen.width - insets.leading - insets.trailing
        )

        let safeHeight = max(
            0,
            screen.height - insets.top - insets.bottom
        )

        let compact = safeHeight < 650

        let buttonWidth = max(
            0,
            min(340, safeWidth - 48)
        )

        return ZStack {

            // MARK: - Portrait Settings & Large Title

            VStack(spacing: compact ? 8 : 14) {
                HStack {
                    Spacer(minLength: 0)
                    settingsButton
                }
                .padding(.trailing, 16)
                .padding(.top, 8)

                titleLogo
                    .frame(
                        maxWidth: safeWidth * 0.92,
                        maxHeight: compact ? 110 : 150
                    )
                    .padding(.horizontal, 12)

                Spacer(minLength: 0)
            }

            // MARK: - Portrait Action Buttons

            VStack(spacing: 0) {

                Spacer(minLength: 0)

                VStack(
                    spacing: compact ? 10 : 14
                ) {
                    playButton
                    howToPlayButton
                }
                .frame(width: buttonWidth)
                .padding(
                    .bottom,
                    compact ? 16 : 28
                )
            }
        }
        .frame(
            width: safeWidth,
            height: safeHeight
        )
        .position(
            x: insets.leading + safeWidth / 2,
            y: insets.top + safeHeight / 2
        )
    }

    // MARK: - Landscape Controls

    private func landscapeControls(
        screen: CGSize,
        insets: EdgeInsets
    ) -> some View {

        let compact = screen.height < 400
        let gap: CGFloat = compact ? 10 : 12
        let settingsSize: CGFloat = 46
        let playHeight: CGFloat = 52
        let secondaryHeight: CGFloat = 46
        let titleMaxHeight: CGFloat = compact ? 110 : 140

        // Buttons stay compact while the title
        // spans the right-side parchment space.

        let panelWidth = min(
            290,
            max(220, screen.width * 0.25)
        )

        let rightZoneStart = screen.width * 0.64999
        let rightZoneEnd = screen.width - insets.trailing - 12

        let availableTitleWidth = max(
            panelWidth,
            rightZoneEnd - rightZoneStart
        )

        let titleWidth = min(500, availableTitleWidth)

        let groupHeight =
            titleMaxHeight + gap + playHeight + gap + secondaryHeight

        // MARK: - Horizontal Position

        let preferredCenterX = screen.width * 0.78
        let maxCenterX = rightZoneEnd - titleWidth / 2
        let minCenterX = rightZoneStart + titleWidth / 2

        let centerX = max(
            minCenterX,
            min(preferredCenterX, maxCenterX)
        )

        // MARK: - Vertical Position

        let preferredCenterY = screen.height * 0.45

        let maxCenterY =
            screen.height
            - insets.bottom
            - 12
            - groupHeight / 2

        let centerY = min(
            preferredCenterY,
            maxCenterY
        )

        return VStack(spacing: gap) {

            // MARK: - Oversized Title PNG

            titleLogo
                .frame(
                    width: titleWidth,
                    height: titleMaxHeight
                )
                .padding(.bottom, compact ? 2 : 6)

            // MARK: - Main Action

            playButton
                .frame(width: panelWidth)

            // MARK: - Secondary Actions

            HStack(spacing: gap) {

                howToPlayButton
                    .frame(maxWidth: .infinity)

                settingsButton
                    .frame(
                        width: settingsSize,
                        height: settingsSize
                    )
            }
            .frame(width: panelWidth)
        }
        .position(
            x: centerX,
            y: centerY
        )
        .frame(
            width: screen.width,
            height: screen.height
        )
    }

    // MARK: - Settings Button

    private var settingsButton: some View {
        Button {
            showSettings = true
        } label: {

            Image(systemName: "gearshape.fill")
                .font(
                    .system(
                        size: 21,
                        weight: .semibold
                    )
                )
                .foregroundStyle(darkBrown)
                .frame(
                    width: 46,
                    height: 46
                )
                .background(
                    lightTan,
                    in: Circle()
                )
                .overlay {
                    Circle()
                        .stroke(
                            darkBrown,
                            lineWidth: 2
                        )
                }
                .shadow(
                    color: .black.opacity(0.18),
                    radius: 3,
                    y: 2
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Settings")
    }

    // MARK: - Play Button
    // Restore verified Firebase accounts.
    // Keep the original button appearance.

    private var playButton: some View {
        NavigationLink {
            if auth.isLoggedIn && auth.isEmailVerified {
                GameBoardView()
                    .navigationBarBackButtonHidden(true)
                    .toolbar(
                        .hidden,
                        for: .navigationBar
                    )
                    .onAppear {
                        entryMode = "account"
                        GameRecordStore.shared
                            .refreshForCurrentAccount()
                    }
            } else {
                WelcomeView()
            }
        } label: {

            Text("Play")
                .font(
                    .system(
                        size: 20,
                        weight: .bold
                    )
                )
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    darkBrown,
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .stroke(
                            darkBrown,
                            lineWidth: 2
                        )
                }
                .shadow(
                    color: .black.opacity(0.25),
                    radius: 5,
                    y: 2
                )
        }
        .buttonStyle(.plain)
        .disabled(!auth.hasCheckedAuthState)
    }

    // MARK: - How to Play Button

    private var howToPlayButton: some View {
        Button {
            showHowToPlay = true
        } label: {

            Text("How to Play")
                .font(
                    .system(
                        size: 18,
                        weight: .bold
                    )
                )
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .foregroundStyle(darkBrown)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    lightTan,
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .stroke(
                            darkBrown,
                            lineWidth: 2
                        )
                }
                .shadow(
                    color: .black.opacity(0.15),
                    radius: 3,
                    y: 2
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - How to Play
// MARK: - First Play Guided Tutorial

struct GameTutorialView: View {
    var onCompleted: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    @State private var step = 0
    @State private var inspectedCard = false
    @State private var practiceComplete = false
    @State private var cardOffset: CGSize = .zero
    @State private var isCardPressed = false

    private let paper = Color(
        red: 255/255,
        green: 243/255,
        blue: 228/255
    )

    private let tan = Color(
        red: 252/255,
        green: 220/255,
        blue: 187/255
    )

    private let brown = Color(
        red: 89/255,
        green: 59/255,
        blue: 46/255
    )

    private let green = Color(
        red: 224/255,
        green: 238/255,
        blue: 205/255
    )

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
                    .overlay(tan.opacity(0.38))
                    .allowsHitTesting(false)

                VStack(spacing: compact ? 10 : 16) {
                    header(compact: compact)

                    HStack(spacing: 5) {
                        ForEach(0..<5, id: \.self) { index in
                            Capsule()
                                .fill(
                                    index <= step
                                        ? brown
                                        : brown.opacity(0.17)
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
                                tan.opacity(0.46),
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
                    paper,
                    in: RoundedRectangle(cornerRadius: 24)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            brown.opacity(0.55),
                            lineWidth: 1.6
                        )
                }
                .shadow(
                    color: brown.opacity(0.22),
                    radius: 13,
                    y: 7
                )
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .background(tan.ignoresSafeArea())
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
                .foregroundStyle(brown.opacity(0.72))

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
        }
        .foregroundStyle(brown)
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
                .foregroundStyle(brown.opacity(0.65))

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
                .foregroundStyle(brown.opacity(0.88))

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
                    canAdvance ? green : tan,
                    in: RoundedRectangle(cornerRadius: 12)
                )
            }

            Spacer(minLength: 0)
        }
        .foregroundStyle(brown)
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
                .foregroundStyle(brown)
                .background(tan, in: Capsule())
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
            .foregroundStyle(paper)
            .background(
                canAdvance
                    ? brown
                    : brown.opacity(0.40),
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
                    .foregroundStyle(brown)
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
                        .foregroundStyle(brown)
                        .background(paper, in: Circle())
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
                .foregroundStyle(brown)
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
                        .foregroundStyle(brown)

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
                        .foregroundStyle(brown)
                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                    .background(
                        practiceComplete ? green : paper,
                        in: RoundedRectangle(
                            cornerRadius: 14
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                brown.opacity(0.7),
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

// MARK: - Responsive Tutorial Layout
// Original gameplay instructions are preserved.

struct HowToPlaySheetView: View {

    @Environment(\.dismiss)
    private var dismiss

    // MARK: - Colors

    private let backgroundTan = Color(
        red: 252.0 / 255,
        green: 220.0 / 255,
        blue: 187.0 / 255
    )

    private let paper = Color(
        red: 255.0 / 255,
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

    // MARK: - Main Layout

    var body: some View {
        GeometryReader { geometry in

            let compact = geometry.size.height < 410

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
                                    .fill(outline)
                                    .frame(height: 1)

                                Image(
                                    systemName: "swords"
                                )
                                .font(.system(size: 18))

                                Rectangle()
                                    .fill(outline)
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
                                    brown,
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                    .foregroundStyle(brown)
                    .padding(compact ? 14 : 20)
                    .background(
                        paper.opacity(0.58),
                        in: RoundedRectangle(cornerRadius: 22)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(
                                outline.opacity(0.85),
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
        .presentationBackground(backgroundTan)
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
            paper,
            in: RoundedRectangle(cornerRadius: 10)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(outline.opacity(0.55))
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
                .fill(outline.opacity(0.7))
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
        .padding(compact ? 10 : 15)
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

// MARK: - Preview

#Preview {
    NavigationStack {
        HomeView()
    }
    .environmentObject(GameManager())
    .environmentObject(AuthManager())
}

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

// MARK: - In-game Help Options

struct BattleGuideOptionsView: View {

    enum Action {
        case tutorial
        case cards
    }

    let select: (Action) -> Void

    @Environment(\.dismiss)
    private var dismiss

    private let paper = Color(
        red: 255/255,
        green: 243/255,
        blue: 228/255
    )

    private let brown = Color(
        red: 89/255,
        green: 59/255,
        blue: 46/255
    )

    private let tan = Color(
        red: 252/255,
        green: 220/255,
        blue: 187/255
    )

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("gameboardbg")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .clipped()
                    .overlay(
                        tan.opacity(0.56)
                    )

                VStack(spacing: 10) {
                    HStack {
                        Text("TRAINING & HELP")
                            .font(
                                .system(
                                    size: 13,
                                    weight: .black,
                                    design: .rounded
                                )
                            )
                            .tracking(1.4)

                        Spacer()

                        Button {
                            dismiss()
                        } label: {
                            Image(
                                systemName: "xmark.circle.fill"
                            )
                            .font(
                                .system(size: 23)
                            )
                        }
                    }

                    Text("Need a refresher?")
                        .font(
                            .system(
                                size: 27,
                                weight: .black,
                                design: .serif
                            )
                        )

                    Text(
                        "Your current battle stays exactly as it is."
                    )
                    .font(.system(size: 12))
                    .foregroundStyle(
                        brown.opacity(0.75)
                    )

                    helpRow(
                        "Replay Interactive Tutorial",
                        icon: "hand.draw.fill",
                        note: "Practice holding and dragging cards"
                    ) {
                        select(.tutorial)
                    }

                    helpRow(
                        "Cards & Characters",
                        icon: "book.closed.fill",
                        note: "Read abilities, effects and battle rules"
                    ) {
                        select(.cards)
                    }
                }
                .foregroundStyle(brown)
                .padding(19)
                .frame(maxWidth: 490)
                .background(
                    paper,
                    in: RoundedRectangle(
                        cornerRadius: 23
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: 23
                    )
                    .stroke(
                        brown,
                        lineWidth: 1.5
                    )
                }
                .padding(.horizontal, 20)
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .ignoresSafeArea()
        .environment(\.colorScheme, .light)
    }

    private func helpRow(
        _ title: String,
        icon: String,
        note: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: icon)
                    .font(
                        .system(size: 22)
                    )
                    .frame(width: 36)

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {
                    Text(title)
                        .font(
                            .system(
                                size: 15,
                                weight: .bold
                            )
                        )

                    Text(note)
                        .font(
                            .system(size: 11)
                        )
                        .foregroundStyle(
                            brown.opacity(0.7)
                        )
                }

                Spacer(minLength: 0)

                Image(
                    systemName: "chevron.right"
                )
            }
            .padding(12)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(
                tan,
                in: RoundedRectangle(
                    cornerRadius: 13
                )
            )
        }
        .buttonStyle(.plain)
    }
}

