//
//  GameBoardView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/11/26.
//

import SwiftUI

struct GameBoardView: View {
    @EnvironmentObject var game: GameManager
    @Environment(\.dismiss) var dismiss
    
    @State private var draggedCard: HealerCard?
    @State private var dragLocation = CGPoint.zero
    @State private var teammateFrames: [UUID: CGRect] = [:]
    @State private var handFrame = CGRect.zero

    private func finishDrag(_ card: HealerCard, at point: CGPoint) {
        draggedCard = nil
        withAnimation {
            if let target = game.livingTeammates.first(where: { teammateFrames[$0.id]?.contains(point) == true }) {
                game.assignCard(card: card, to: target)
            } else if handFrame.contains(point) {
                game.returnToHand(card: card)
            }
        }
    }

    private func moveDrag(_ card: HealerCard, to point: CGPoint) {
        draggedCard = card
        dragLocation = point
    }

    var body: some View {
        ZStack {
            // Background Color
            Color(red: 252 / 255, green: 220 / 255, blue: 187 / 255)
                .ignoresSafeArea()
            
            if game.isResolving {
                EncounterResolutionView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.96)),
                        removal: .opacity
                    ))
            } else {
                GeometryReader { geometry in
                    let portrait = geometry.size.width < geometry.size.height
                    let columns = portrait ? AnyLayout(VStackLayout(spacing: 0)) : AnyLayout(HStackLayout(spacing: 0))
                    columns {
                        
                        // LEFT COLUMN: encounter label + Idiots row + healer cards
                        VStack(spacing: 0) {
                            Text("Assign Your Healer Cards")
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .padding(.top, 12)
                            
                            Spacer(minLength: 5)
                            
                            // idiots row
                            VStack {
                                HStack(alignment: .top, spacing: 8) {
                                    ForEach(game.teammates) { teammate in
                                        TeammateCardView(teammate: teammate, onCardMove: moveDrag, onCardDrop: finishDrag)
                                            .onGeometryChange(for: CGRect.self) { proxy in
                                                proxy.frame(in: .named("healerBoard"))
                                            } action: { frame in
                                                teammateFrames[teammate.id] = frame
                                            }
                                    }
                                }
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 245/255, green: 215/255, blue: 180/255))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.brown, lineWidth: 2)
                                    )
                            )
                            .padding(.horizontal, 10)
                            
                            Spacer(minLength: 4)
                            
                            
                            // healer 'your cards' hand row
                            HStack(spacing: portrait ? 8 : 120) {
                                VStack {
                                    Image("healer card")
                                        .resizable()
                                        .scaledToFit()
                                        .scaleEffect(portrait ? 1 : 2)
                                        .offset(x: portrait ? 0 : 64)
                                        .frame(width: portrait ? 56 : 100, height: 100)      .zIndex(-1)
                                }
                                //healer cards
                                HStack(spacing:4) {
                                    let stagedCards = game.pendingThefts.map(\.card)
                                    let cards = stagedCards.isEmpty ? game.availableCards :
                                        HealerCard.allCases.filter { game.availableCards.contains($0) || stagedCards.contains($0) }
                                    ForEach(cards, id: \.self) { card in
                                        let image = Image(card.imageName)
                                            .resizable().scaledToFit()
                                            .frame(width: portrait ? min(70, geometry.size.width / 6) : nil, height: 120)
                                        if stagedCards.contains(card) {
                                            image.hidden()
                                                .anchorPreference(key: TheftAnchors.self, value: .bounds) {
                                                    [.hand(card): $0]
                                                }
                                        } else {
                                            image.shadow(color: .black.opacity(0.2), radius: 8, y: 1)
                                                .modifier(HealerCardDrag(card: card, onMove: moveDrag, onDrop: finishDrag))
                                        }
                                    }
                                }
                                .frame(minHeight: 95)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                            .onGeometryChange(for: CGRect.self) { proxy in
                                proxy.frame(in: .named("healerBoard"))
                            } action: { frame in
                                handFrame = frame
                            }
                            .dropDestination(for: String.self) { items, _ in
                                guard let rawCard = items.first,
                                      let healerCard = HealerCard(rawValue: rawCard) else { return false }
                                
                                withAnimation {
                                    game.returnToHand(card: healerCard)
                                }
                                return true
                            }
                        }
                        .frame(width: geometry.size.width * (portrait ? 1 : 0.80))
                        
                        // RIGHT COLUMN: BONK section
                        let bossLayout = portrait ? AnyLayout(HStackLayout(spacing: 6)) : AnyLayout(VStackLayout(spacing: 20))
                        bossLayout {
                            VStack(spacing: 5) {
                                
                                
                                Text("\(max(0, game.bonkHP)) / 5 HP")
                                    .font(.headline)
                                    .font(.headline).bold()
                                    .foregroundColor(.black)
                                    .offset(x: portrait ? 0 : -8, y: portrait ? 0 : 74)
                                    
                                                                }
                            .padding(.top, 30)
                            
                            Image("bonk cave")
                                .resizable()
                                .scaledToFit()
                                .scaleEffect(1.6)
                                .rotationEffect(.degrees(270))
                                .offset(x: -12, y: 24)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .layoutPriority(-1)
                                 .zIndex(-1)
                            
                            Spacer()
                            
                            VStack(spacing: 10) {
                                
                                
                                
                                Button(action: {
                                    withAnimation { game.resolveEncounter() }
                                }) {
                                    Text("Begin Encounter")
                                        .font(.headline).bold()
                                        .foregroundColor(.white)
                                        .frame(width: 200, height: 45)
                                        .background(game.allLivingAssigned && !game.isGameOver ? Color.green : Color.gray)
                                        .cornerRadius(25)
                                        .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color.gray.opacity(0.5), lineWidth: 3))
                                }
                                .disabled(!game.allLivingAssigned || game.isGameOver)
                                
                                
                            }
                            .padding(.bottom, 20)
                        }
                        .frame(width: geometry.size.width * (portrait ? 1 : 0.35))
                        .frame(height: portrait ? 108 : nil)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .disabled(!game.pendingThefts.isEmpty)
                .overlayPreferenceValue(TheftAnchors.self) { anchors in
                    GeometryReader { proxy in
                        ForEach(game.pendingThefts) { theft in
                            if let hand = anchors[.hand(theft.card)], let panel = anchors[.panel(theft.id)] {
                                BoardGhostFlight(card: theft.card, hand: proxy[hand], panel: proxy[panel]) {
                                    game.finishGhostTheft(theft.id)
                                }
                            }
                        }
                    }
                    .allowsHitTesting(false)
                }
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .scale(scale: 0.85, anchor: .top).combined(with: .opacity)
                ))
            }
            
            if let draggedCard {
                Image(draggedCard.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 70)
                    .shadow(radius: 3)
                    .position(dragLocation)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }

            // GAME OVER OVERLAY (You Win / You Lost)
            if game.isGameOver {
                GameOverOverlayView(
                    didWin: game.didPlayerWin,
                    onPlayAgain: {
                        game.resetGame()
                    },
                    onReturnHome: {
                        game.resetGame()
                        dismiss()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .zIndex(10)
            }
        }
        .coordinateSpace(name: "healerBoard")
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

struct HealerCardDrag: ViewModifier {
    let card: HealerCard
    let onMove: (HealerCard, CGPoint) -> Void
    let onDrop: (HealerCard, CGPoint) -> Void

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 5, coordinateSpace: .named("healerBoard"))
                    .onChanged { onMove(card, $0.location) }
                    .onEnded { onDrop(card, $0.location) }
            )
    }
}

struct GameOverOverlayView: View {
    let didWin: Bool
    let onPlayAgain: () -> Void
    let onReturnHome: () -> Void
    
    let darkBrown = Color(red: 0.35, green: 0.23, blue: 0.18)
    let cardTan = Color(red: 0.98, green: 0.88, blue: 0.74)
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 18) {
                Text(didWin ? "YOU WIN!" : "YOU LOST!")
                    .font(.system(size: 38, weight: .black, design: .serif))
                    .foregroundColor(didWin ? .green : .red)
                
                Text(didWin ? "Bonk has been defeated!" : "Two idiots became ghosts!")
                    .font(.headline)
                    .foregroundColor(darkBrown)
                
                HStack(spacing: 16) {
                    Button(action: onPlayAgain) {
                        Text("Play Again")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(width: 140, height: 44)
                            .background(Color.green)
                            .cornerRadius(22)
                    }
                    
                    Button(action: onReturnHome) {
                        Text("Return Home")
                            .font(.headline.bold())
                            .foregroundColor(darkBrown)
                            .frame(width: 140, height: 44)
                            .background(Color.white)
                            .cornerRadius(22)
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(darkBrown, lineWidth: 2))
                    }
                }
                .padding(.top, 6)
            }
            .padding(28)
            .background(cardTan)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(darkBrown, lineWidth: 3))
            .shadow(radius: 15)
        }
    }
}

#Preview {
    GameBoardView()
        .environmentObject(GameManager())
}
