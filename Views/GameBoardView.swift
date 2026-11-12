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
                    HStack(spacing: 0) {
                        
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
                                        TeammateCardView(teammate: teammate)
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
                            HStack(spacing: 120) {
                                VStack {
                                    Image("healer card")
                                        .resizable()
                                        .scaledToFit()
                                        .scaleEffect(2)
                                        .offset(x:64)
                                        .frame(width: 100, height: 100)      .zIndex(-1)
                                }
                                //healer cards
                                HStack(spacing:4) {
                                  ForEach(game.availableCards, id: \.self) { card in
                                   Image(card.imageName)
                                      .resizable()
                                      .scaledToFit()
                                       .frame(height: 120)
                                       .shadow(color: .black.opacity(0.2), radius: 8, y: 1)
                                       .draggable(card.rawValue)
                                                                    }
                                                                }
                                .frame(minHeight: 95)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                            .dropDestination(for: String.self) { items, _ in
                                guard let rawCard = items.first,
                                      let healerCard = HealerCard(rawValue: rawCard) else { return false }
                                
                                withAnimation {
                                    game.returnToHand(card: healerCard)
                                }
                                return true
                            }
                        }
                        .frame(width: geometry.size.width * 0.80)
                        
                        // RIGHT COLUMN: BONK section
                        VStack(spacing: 20) {
                            VStack(spacing: 5) {
                                
                                
                                Text("\(max(0, game.bonkHP)) / 5 HP")
                                    .font(.headline)
                                    .font(.headline).bold()
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
                        .frame(width: geometry.size.width * 0.35)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .scale(scale: 0.85, anchor: .top).combined(with: .opacity)
                ))
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
