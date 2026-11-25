//
//  BattleGuideOptionsView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/25/26.
//

import SwiftUI

// MARK: - In-game Help Options

struct BattleGuideOptionsView: View {

    enum Action {
        case tutorial
        case cards
    }

    let select: (Action) -> Void

    @Environment(\.dismiss)
    private var dismiss

   

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
                        AppTheme.backgroundTan.opacity(0.56)
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
                        AppTheme.darkBrown.opacity(0.75)
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
                .foregroundStyle(AppTheme.darkBrown)
                .padding(19)
                .frame(maxWidth: 490)
                .background(
                    AppTheme.paper,
                    in: RoundedRectangle(
                        cornerRadius: 23
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: 23
                    )
                    .stroke(
                        AppTheme.darkBrown,
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
                            AppTheme.darkBrown.opacity(0.7)
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
                AppTheme.backgroundTan,
                in: RoundedRectangle(
                    cornerRadius: 13
                )
            )
        }
        .buttonStyle(.plain)
    }
}
