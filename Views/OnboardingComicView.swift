//
//  OnboardingComicView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/25/26.
//

import SwiftUI

// screen panel names

enum OnboardingAsset {
    static let tapToStart = "taptostart"
    static let panel1Exit = "intro_01_exit"
    static let panel2Bonk = "intro_02_bonk"
    static let panel3HealerChaos = "intro_03_healer_chaos"
    static let panel4Vampire = "intro_04_vampire"
    static let panel5Knight = "intro_05_knight"
    static let panel6Boom = "intro_06_boom"
    static let panel7YouAreHealer = "intro_07_you_are_healer"
}

// screen mapping

private struct ComicPanelSpec: Identifiable {
    let id: Int // Global reveal index 0...6
    let imageName: String
    let fallbackLabel: String
    let fallbackColor: Color
    let skewDegrees: Double
    let alignment: Alignment
}

private enum ComicScreen: Int, CaseIterable {
    case screen1 = 0
    case screen2 = 1
    case screen3 = 2

    static func from(revealIndex: Int) -> ComicScreen {
        switch revealIndex {
        case 0...1:
            return .screen1
        case 2...5:
            return .screen2
        default:
            return .screen3
        }
    }
}

// main onboarding view

struct OnboardingComicView: View {
    let onFinish: () -> Void
    let onSkip: () -> Void

    init(
        onFinish: @escaping () -> Void = {},
        onSkip: @escaping () -> Void = {}
    ) {
        self.onFinish = onFinish
        self.onSkip = onSkip
    }

    @State private var showTapToStart: Bool = true
    @State private var isPulsing: Bool = false
    @State private var revealIndex: Int = 0
    @State private var newlyRevealedIndex: Int? = nil

    private let panel0 = ComicPanelSpec(
        id: 0,
        imageName: OnboardingAsset.panel1Exit,
        fallbackLabel: "1 · Exit",
        fallbackColor: Color(red: 0.94, green: 0.85, blue: 0.72),
        skewDegrees: -1.1,
        alignment: .center
    )

    private let panel1 = ComicPanelSpec(
        id: 1,
        imageName: OnboardingAsset.panel2Bonk,
        fallbackLabel: "2 · Bonk",
        fallbackColor: Color(red: 0.91, green: 0.78, blue: 0.63),
        skewDegrees: 1.0,
        alignment: .center
    )

    private let panel2 = ComicPanelSpec(
        id: 2,
        imageName: OnboardingAsset.panel3HealerChaos,
        fallbackLabel: "3 · Healer Chaos",
        fallbackColor: Color(red: 0.93, green: 0.82, blue: 0.68),
        skewDegrees: -0.9,
        alignment: .center
    )

    private let panel3 = ComicPanelSpec(
        id: 3,
        imageName: OnboardingAsset.panel4Vampire,
        fallbackLabel: "4 · Vampire",
        fallbackColor: Color(red: 0.89, green: 0.75, blue: 0.64),
        skewDegrees: 0.8,
        alignment: .top
    )

    private let panel4 = ComicPanelSpec(
        id: 4,
        imageName: OnboardingAsset.panel5Knight,
        fallbackLabel: "5 · Knight",
        fallbackColor: Color(red: 0.95, green: 0.86, blue: 0.71),
        skewDegrees: -0.8,
        alignment: .center
    )

    private let panel5 = ComicPanelSpec(
        id: 5,
        imageName: OnboardingAsset.panel6Boom,
        fallbackLabel: "6 · Boom",
        fallbackColor: Color(red: 0.92, green: 0.76, blue: 0.60),
        skewDegrees: 0.9,
        alignment: .center
    )

    private let panel6 = ComicPanelSpec(
        id: 6,
        imageName: OnboardingAsset.panel7YouAreHealer,
        fallbackLabel: "7 · You Are Healer",
        fallbackColor: Color(red: 0.94, green: 0.84, blue: 0.69),
        skewDegrees: -0.6,
        alignment: .center
    )

    private let totalPanels = 7
    private let parchmentBG = Color(red: 0.98, green: 0.93, blue: 0.84)
    private let inkBrown = Color(red: 0.27, green: 0.16, blue: 0.10)

    private var currentScreen: ComicScreen {
        ComicScreen.from(revealIndex: revealIndex)
    }

    var body: some View {
        ZStack {
            if showTapToStart {
                tapToStartScreen
                    .transition(.opacity)
            } else {
                comicStorylineView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: showTapToStart)
        .environment(\.colorScheme, .light)
    }

    // tap to start screen

    private var tapToStartScreen: some View {
        ZStack {
            parchmentBG
                .ignoresSafeArea()

            if let uiImage = UIImage(named: OnboardingAsset.tapToStart) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .scaleEffect(isPulsing ? 1.015 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                        value: isPulsing
                    )
            } else {
                VStack(spacing: 12) {
                    Text("My Healer Sucks")
                        .font(.system(.largeTitle, design: .serif).weight(.bold))
                        .foregroundStyle(inkBrown)
                    Text("Tap to Start")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(inkBrown.opacity(0.8))
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            startStoryline()
        }
        .onAppear {
            isPulsing = true
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("My Healer Sucks. Tap to start.")
        .accessibilityAddTraits(.isButton)
    }

    private func startStoryline() {
        withAnimation(.easeInOut(duration: 0.45)) {
            showTapToStart = false
        }
    }

    // comic storyline view

    private var comicStorylineView: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let gutter = max(5, min(width, height) * 0.014)
            let horizontalPad = max(8, width * 0.015)
            let verticalPad = max(4, height * 0.01)

            VStack(spacing: verticalPad * 0.6) {
                ComicTopBar(inkColor: inkBrown)

                comicStage(
                    totalWidth: max(0, width - horizontalPad * 2),
                    gutter: gutter
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                ComicBottomBar(
                    canGoBack: revealIndex > 0,
                    isFinalStep: revealIndex >= totalPanels - 1,
                    inkColor: inkBrown,
                    surfaceColor: parchmentBG,
                    onBack: stepBack,
                    onSkip: onSkip,
                    onNext: stepNext
                )
            }
            .padding(.horizontal, horizontalPad)
            .padding(.vertical, verticalPad)
            .frame(width: width, height: height)
            .background(parchmentBG.ignoresSafeArea())
        }
    }

    // each screen layout

    @ViewBuilder
    private func comicStage(totalWidth: CGFloat, gutter: CGFloat) -> some View {
        let usableWidth = max(0, totalWidth - gutter)

        switch currentScreen {
        case .screen1:
            HStack(spacing: gutter) {
                ComicPanel(
                    spec: panel0,
                    isRevealed: revealIndex >= panel0.id,
                    shouldAnimateIn: newlyRevealedIndex == panel0.id,
                    parchmentColor: parchmentBG,
                    inkColor: inkBrown
                )
                .frame(width: usableWidth * 0.58)
                .frame(maxHeight: .infinity)

                ComicPanel(
                    spec: panel1,
                    isRevealed: revealIndex >= panel1.id,
                    shouldAnimateIn: newlyRevealedIndex == panel1.id,
                    parchmentColor: parchmentBG,
                    inkColor: inkBrown
                )
                .frame(width: usableWidth * 0.42)
                .frame(maxHeight: .infinity)
            }

        case .screen2:
            let rightWidth = usableWidth * 0.48
            let stackedGutter = gutter * 2

            HStack(spacing: gutter) {
                ComicPanel(
                    spec: panel2,
                    isRevealed: revealIndex >= panel2.id,
                    shouldAnimateIn: newlyRevealedIndex == panel2.id,
                    parchmentColor: parchmentBG,
                    inkColor: inkBrown
                )
                .frame(width: usableWidth * 0.52)
                .frame(maxHeight: .infinity)

                GeometryReader { rightGeo in
                    let slotHeight = max(0, (rightGeo.size.height - stackedGutter) / 3)

                    VStack(spacing: gutter) {
                        ComicPanel(
                            spec: panel3,
                            isRevealed: revealIndex >= panel3.id,
                            shouldAnimateIn: newlyRevealedIndex == panel3.id,
                            parchmentColor: parchmentBG,
                            inkColor: inkBrown
                        )
                        .frame(height: slotHeight)

                        ComicPanel(
                            spec: panel4,
                            isRevealed: revealIndex >= panel4.id,
                            shouldAnimateIn: newlyRevealedIndex == panel4.id,
                            parchmentColor: parchmentBG,
                            inkColor: inkBrown
                        )
                        .frame(height: slotHeight)

                        ComicPanel(
                            spec: panel5,
                            isRevealed: revealIndex >= panel5.id,
                            shouldAnimateIn: newlyRevealedIndex == panel5.id,
                            parchmentColor: parchmentBG,
                            inkColor: inkBrown
                        )
                        .frame(height: slotHeight)
                    }
                }
                .frame(width: rightWidth)
                .frame(maxHeight: .infinity)
            }

        case .screen3:
            ComicPanel(
                spec: panel6,
                isRevealed: revealIndex >= panel6.id,
                shouldAnimateIn: newlyRevealedIndex == panel6.id,
                parchmentColor: parchmentBG,
                inkColor: inkBrown
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // manual "next" action

    private func stepNext() {
        if revealIndex < totalPanels - 1 {
            let nextIndex = revealIndex + 1
            newlyRevealedIndex = nextIndex
            revealIndex = nextIndex
        } else {
            onFinish()
        }
    }

    private func stepBack() {
        guard revealIndex > 0 else { return }
        newlyRevealedIndex = nil
        revealIndex -= 1
    }
}

// comic panel

private struct ComicPanel: View {
    let spec: ComicPanelSpec
    let isRevealed: Bool
    let shouldAnimateIn: Bool
    let parchmentColor: Color
    let inkColor: Color

    @State private var slideOffsetRatio: CGFloat = 0

    var body: some View {
        let shape = AngledComicPanelShape(skewDegrees: spec.skewDegrees)

        GeometryReader { geo in
            ZStack {
                parchmentColor

                if isRevealed {
                    panelArtwork(in: geo.size)
                        .offset(x: geo.size.width * slideOffsetRatio)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipShape(shape)
            .overlay {
                shape.stroke(inkColor, lineWidth: 1.75)
            }
            .onAppear {
                triggerSlideIfNeeded()
            }
            .onChange(of: isRevealed) { _, revealed in
                if revealed {
                    triggerSlideIfNeeded()
                } else {
                    slideOffsetRatio = 0
                }
            }
            .onChange(of: shouldAnimateIn) { _, animate in
                if animate && isRevealed {
                    triggerSlideIfNeeded()
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isRevealed ? spec.fallbackLabel : "Unrevealed panel")
    }

    @ViewBuilder
    private func panelArtwork(in size: CGSize) -> some View {
        if let uiImage = UIImage(named: spec.imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height, alignment: spec.alignment)
                .clipped()
        } else {
            ZStack {
                spec.fallbackColor.opacity(0.65)

                VStack(spacing: 4) {
                    Text(spec.fallbackLabel)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(inkColor)
                        .minimumScaleFactor(0.75)
                        .lineLimit(1)

                    Text(spec.imageName)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(inkColor.opacity(0.75))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
            }
        }
    }

    private func triggerSlideIfNeeded() {
        guard isRevealed else { return }
        if shouldAnimateIn {
            slideOffsetRatio = 1.0
            withAnimation(.easeOut(duration: 0.4)) {
                slideOffsetRatio = 0
            }
        } else {
            slideOffsetRatio = 0
        }
    }
}

// manga frames

private struct AngledComicPanelShape: Shape {
    let skewDegrees: Double

    func path(in rect: CGRect) -> Path {
        let radians = skewDegrees * .pi / 180.0
        let deltaY = tan(radians) * rect.width * 0.08
        let inset: CGFloat = 1.5

        let topLeft = CGPoint(x: rect.minX + inset, y: rect.minY + inset - deltaY * 0.5)
        let topRight = CGPoint(x: rect.maxX - inset, y: rect.minY + inset + deltaY * 0.5)
        let bottomRight = CGPoint(x: rect.maxX - inset, y: rect.maxY - inset - deltaY * 0.5)
        let bottomLeft = CGPoint(x: rect.minX + inset, y: rect.maxY - inset + deltaY * 0.5)

        var path = Path()
        path.move(to: topLeft)
        path.addLine(to: topRight)
        path.addLine(to: bottomRight)
        path.addLine(to: bottomLeft)
        path.closeSubpath()
        return path
    }
}

// top header

private struct ComicTopBar: View {
    let inkColor: Color

    var body: some View {
        HStack {
            Spacer(minLength: 0)
            Text("THE BACKSTORY")
                .font(.system(.headline, design: .serif).weight(.semibold))
                .foregroundStyle(inkColor.opacity(0.9))
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }
}

// bottom nav

private struct ComicBottomBar: View {
    let canGoBack: Bool
    let isFinalStep: Bool
    let inkColor: Color
    let surfaceColor: Color
    let onBack: () -> Void
    let onSkip: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.caption.weight(.bold))
                    Text("Back")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                }
                .foregroundStyle(canGoBack ? inkColor : inkColor.opacity(0.3))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(surfaceColor, in: Capsule())
                .overlay {
                    Capsule().stroke(canGoBack ? inkColor : inkColor.opacity(0.3), lineWidth: 1.5)
                }
            }
            .buttonStyle(.plain)
            .disabled(!canGoBack)

            Spacer()

            HStack(spacing: 10) {
                Button(action: onSkip) {
                    Text("Skip intro")
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .foregroundStyle(inkColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(surfaceColor, in: Capsule())
                        .overlay {
                            Capsule().stroke(inkColor, lineWidth: 1.5)
                        }
                }
                .buttonStyle(.plain)

                Button(action: onNext) {
                    HStack(spacing: 4) {
                        Text(isFinalStep ? "Let’s go." : "Next")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                        if !isFinalStep {
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                        }
                    }
                    .foregroundStyle(surfaceColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(inkColor, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview("Landscape Onboarding") {
    OnboardingComicView(
        onFinish: {},
        onSkip: {}
    )
}
