//
//  GameOverOverlayView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/25/26.
//
import SwiftUI

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

    private let victoryGreen = Color(red: 0.15, green: 0.40, blue: 0.19)
    private let defeatRed = Color(red: 0.65, green: 0.16, blue: 0.13)

    private func recordStat(_ title: String, value: Int) -> some View {
        VStack(spacing: 3) {
            Text("\(value)")
                .font(.system(size: 23, weight: .black, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(AppTheme.darkBrown)
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.darkBrown.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
    }

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 410

            ZStack {
                Color.black.opacity(0.60)
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: compact ? 12 : 18) {
                        if didWin {
                            Image(systemName: "crown.fill")
                                .font(.system(size: compact ? 32 : 46))
                                .foregroundStyle(victoryGreen)
                        } else {
                            Image("ghost")
                                .resizable()
                                .scaledToFit()
                                .frame(height: compact ? 48 : 68)
                        }

                        Text(didWin ? "Victory!" : "Defeat!")
                            .font(.system(size: compact ? 28 : 36, weight: .black, design: .serif))
                            .foregroundStyle(didWin ? victoryGreen : defeatRed)

                        Text(
                            didWin
                                ? "Bonk has been defeated! Somehow, you kept the idiots alive."
                                : "Too many idiots became ghosts. Better luck keeping them out of trouble next time!"
                        )
                        .font(.system(size: compact ? 13 : 15, weight: .medium, design: .serif))
                        .foregroundStyle(AppTheme.darkBrown)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)

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
                                .accessibilityLabel(
                                    "Updated totals: \(recordUpdate.afterGames) battles, \(recordUpdate.afterVictories) wins, \(recordUpdate.afterDefeats) losses"
                                )
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

                        Button(action: onContinue) {
                            HStack(spacing: 10) {
                                Text("Play Again")
                                Image(systemName: "arrow.right")
                            }
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: compact ? 42 : 48)
                            .background(AppTheme.darkBrown, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Start another battle")
                        .padding(.top, 4)
                    }
                    .padding(compact ? 18 : 26)
                    .frame(maxWidth: 400)
                    .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 22))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(AppTheme.darkBrown.opacity(0.75), lineWidth: 2)
                    }
                    .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
                    .padding(16)
                    .frame(maxWidth: .infinity)
                }
                .frame(maxHeight: geometry.size.height)
            }
        }
    }
}

