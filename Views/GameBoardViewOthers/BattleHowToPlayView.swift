//
//  BattleHowToPlayView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/25/26.
//
import SwiftUI

struct BattleHowToPlayView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 410

            ZStack {
                AppTheme.backgroundTan
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: compact ? 12 : 20) {
                        VStack(spacing: 8) {
                            Text("My Healer Sucks Rulebook")
                                .font(.system(size: compact ? 26 : 32, weight: .black, design: .serif))

                            HStack(spacing: 12) {
                                Rectangle()
                                    .fill(AppTheme.darkBrown.opacity(0.4))
                                    .frame(height: 1)

                                Image(systemName: "swords")

                                Rectangle()
                                    .fill(AppTheme.darkBrown.opacity(0.4))
                                    .frame(height: 1)
                            }
                        }

                        VStack(spacing: compact ? 8 : 12) {
                            ruleCard(
                                "01",
                                "Each idiot(bots) will draw 2 possible moves.",
                                compact: compact
                            )

                            ruleCard(
                                "02",
                                "As the Healer, YOU can drag Heal (+1 HP), Reverse, or Do Nothing onto each idiot before starting the encounter.",
                                compact: compact
                            )

                            ruleCard(
                                "03",
                                "Watch the chaos playout!",
                                compact: compact
                            )

                            ruleCard(
                                "04",
                                "Win by dropping Bonk to 0 HP. Lose if two idiots become ghosts.",
                                compact: compact
                            )
                        }

                    }
                    .foregroundStyle(AppTheme.darkBrown)
                    .padding(compact ? 14 : 20)
                    .background(
                        AppTheme.paper.opacity(0.58),
                        in: RoundedRectangle(cornerRadius: 22)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(AppTheme.darkBrown.opacity(0.45), lineWidth: 1.2)
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
        .presentationBackground(AppTheme.backgroundTan)
    }

    private func ruleCard(
        _ number: String,
        _ text: String,
        compact: Bool
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: compact ? 14 : 17, weight: .bold, design: .serif))
                .frame(width: 28, alignment: .leading)

            Rectangle()
                .fill(AppTheme.darkBrown.opacity(0.35))
                .frame(width: 1)

            Text(text)
                .font(.system(size: compact ? 13 : 15))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(AppTheme.darkBrown)
        .padding(compact ? 10 : 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.darkBrown.opacity(0.35), lineWidth: 1)
        }
    }
}
