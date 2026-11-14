//
//  TeammateCardView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/11/26.
//

import SwiftUI

struct TeammateCardView: View {
    @ObservedObject var teammate: Teammate
    @EnvironmentObject var game: GameManager
    
    let onCardMove: (HealerCard, CGPoint) -> Void
    let onCardDrop: (HealerCard, CGPoint) -> Void

    let cardBackground = Color(red: 0.98, green: 0.85, blue: 0.68)
    let darkBrownText = Color(red: 0.35, green: 0.23, blue: 0.18)
    let mediumBrown = Color(red: 0.65, green: 0.5, blue: 0.4)
    
    var body: some View {
        VStack(spacing: 4) {
            // character id (head + HP)
            HStack(alignment: .top, spacing: 6) {
                Image(teammate.headImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(teammate.name)
                        .font(.system(size: 12, weight: .bold, design: .serif))
                        .foregroundColor(darkBrownText)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    
                    HStack(spacing: 2) {
                        ForEach(0..<teammate.maxHp, id: \.self) { i in
                            Image(systemName: "heart.fill")
                                .foregroundColor(i < teammate.hp ? .red : .gray)
                                .font(.system(size: 11))
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            
            if teammate.isGhost {
                Spacer()
                if let card = game.stolenCards[teammate.id] {
                    GhostWithStolenCard(card: card)
                        .opacity(game.pendingThefts.contains { $0.id == teammate.id } ? 0 : 1)
                        .anchorPreference(key: TheftAnchors.self, value: .bounds) {
                            [.panel(teammate.id): $0]
                        }
                } else {
                    Image("ghost")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 85)
                }
                Text("GHOST\n(Out of play)")
                    .font(.system(size: 12, weight: .bold, design: .serif))
                    .foregroundColor(mediumBrown)
                    .multilineTextAlignment(.center)
                Spacer()
            } else {
                Text("Possible moves")
                    .font(.system(size: 12, weight: .bold, design: .serif))
                    .foregroundColor(darkBrownText)
                
                // idiot's card slot
                HStack(spacing: 6) {
                    MoveOptionBoxView(card: teammate.optionA, textColor: darkBrownText, borderColor: mediumBrown)
                    MoveOptionBoxView(card: teammate.optionB, textColor: darkBrownText, borderColor: mediumBrown)
                }
                .frame(height: 75)
                
                // response dropbox
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.01))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                                .foregroundColor(mediumBrown)
                        )
                        .frame(height: 32)
                    
                    if let card = teammate.assignedCard {
                                            HStack(spacing: 4) {
                                                Image(card.imageName)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: 24)
                                                
                                                Text(card.rawValue)
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(darkBrownText)
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.7)
                                            }
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(Color.white.cornerRadius(6))
                                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(darkBrownText, lineWidth: 1))
                                            .modifier(HealerCardDrag(card: card, onMove: onCardMove, onDrop: onCardDrop))
                                            .simultaneousGesture(TapGesture().onEnded {
                                                withAnimation {
                                                    game.unassignCard(from: teammate)
                                                }
                                            })
                    } else {
                        Text("Drop response here")
                            .font(.system(size: 10, weight: .semibold, design: .serif))
                            .foregroundColor(mediumBrown)
                    }
                }
                .contentShape(Rectangle())
                .dropDestination(for: String.self) { items, _ in
                    guard let rawCard = items.first,
                          let healerCard = HealerCard(rawValue: rawCard) else { return false }
                    
                    withAnimation {
                        game.assignCard(card: healerCard, to: teammate)
                    }
                    return true
                }
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(teammate.isGhost ? cardBackground.opacity(0.65) : cardBackground)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(darkBrownText, lineWidth: 2)
        )
    }
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

struct MoveOptionBoxView: View {
    let card: IdiotCard?
    let textColor: Color
    let borderColor: Color
    
    var body: some View {
        VStack(spacing: 2) {
            if let card = card {
                Text(card.title)
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                
                Spacer(minLength: 0)
                
                Text(card.description)
                    .font(.system(size: 8))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.6)
            } else {
                Text("Empty")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}

#Preview {
    TeammateCardView(teammate: Teammate(character: .drBoomBoom, hp: 3), onCardMove: { _, _ in }, onCardDrop: { _, _ in })
        .environmentObject(GameManager())
        .frame(width: 220, height: 260)
}
