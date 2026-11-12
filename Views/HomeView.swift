//
//  HomeView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/11/26.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var game: GameManager
    @State private var showHowToPlay = false
    
    let lightTan = Color(red: 245 / 255, green: 215 / 255, blue: 180 / 255)
    let darkBrown = Color(red: 0.35, green: 0.23, blue: 0.18)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // full-screen background artwork
                Image("landing")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .allowsHitTesting(false)
                
                // buttons
                VStack(spacing: 12) {
                    NavigationLink(
                        destination: GameBoardView()
                            .navigationBarBackButtonHidden(true)
                    ) {
                        Text("Play")
                            .font(.title3.bold())
                            .foregroundColor(Color.white)
                            .frame(width: 210, height: 48)
                            .background(darkBrown)
                            .cornerRadius(24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(darkBrown, lineWidth: 2)
                            )
                            .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                    }
                    
                    Button(action: {
                        showHowToPlay = true
                    }) {
                        Text("How to Play")
                            .font(.headline.bold())
                            .foregroundColor(darkBrown)
                            .frame(width: 210, height: 42)
                            .background(lightTan)
                            .cornerRadius(21)
                            .overlay(
                                RoundedRectangle(cornerRadius: 21)
                                    .stroke(darkBrown, lineWidth: 2)
                            )
                            .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
                    }
                }
                .position(
                    x: geometry.size.width * 0.82,
                    y: geometry.size.height * 0.63
                )
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showHowToPlay) {
            HowToPlaySheetView()
        }
    }
}

struct HowToPlaySheetView: View {
    @Environment(\.dismiss) var dismiss
    
    let backgroundTan = Color(red: 252 / 255, green: 220 / 255, blue: 187 / 255)
    let darkBrown = Color(red: 0.35, green: 0.23, blue: 0.18)
    
    var body: some View {
        ZStack {
            backgroundTan.ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("How to Play")
                    .font(.system(size: 28, weight: .black, design: .serif))
                    .foregroundColor(darkBrown)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("• Each idiot draws 2 possible moves and will always pick the most self-destructive one.")
                    Text("• Drag Heal (+1 HP), Reverse, or Do Nothing onto each idiot before starting the encounter.")
                    Text("• Use Reverse to redirect self-damage or friendly fire straight onto Bonk!")
                    Text("• Win by dropping Bonk to 0 HP. Lose if two idiots become ghosts.")
                }
                .font(.subheadline)
                .foregroundColor(darkBrown)
                .padding()
                .background(Color.white.opacity(0.6).cornerRadius(12))
                
                Button("Got It") {
                    dismiss()
                }
                .font(.headline.bold())
                .foregroundColor(.white)
                .frame(width: 150, height: 42)
                .background(Color.green)
                .cornerRadius(21)
            }
            .padding(24)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environmentObject(GameManager())
}
