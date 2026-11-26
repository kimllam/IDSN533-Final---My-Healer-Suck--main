//
//  BattleOverlaysView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/25/26.
//
import SwiftUI

// MARK: - Achievement Toast

struct AchievementToastView: View {
    let achievement: BattleAchievement
    let hasMoreAchievements: Bool
    let onNext: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.64)
                .ignoresSafeArea()

            GeometryReader { geometry in
                let compact = geometry.size.height < 420

                VStack(spacing: compact ? 8 : 13) {
                    ZStack {
                        Circle()
                            .fill(Color.yellow.opacity(0.22))
                            .frame(width: compact ? 94 : 130, height: compact ? 94 : 130)
                            .blur(radius: 15)

                        Image(systemName: "sparkles")
                            .font(.system(size: compact ? 76 : 110))
                            .foregroundStyle(Color.orange.opacity(0.55))
                            .symbolEffect(.pulse, options: .repeating)

                        Image(systemName: achievement.icon)
                            .font(.system(size: compact ? 37 : 48, weight: .bold))
                            .foregroundStyle(Color(red: 0.55, green: 0.32, blue: 0.12))
                            .padding(compact ? 17 : 22)
                            .background(AppTheme.lightTan, in: Circle())
                            .overlay(Circle().stroke(AppTheme.darkBrown, lineWidth: 2))
                            .symbolEffect(.bounce, options: .nonRepeating)
                    }

                    Text("ACHIEVEMENT UNLOCKED!")
                        .font(.system(size: compact ? 12 : 15, weight: .black, design: .rounded))
                        .tracking(2)

                    Text(achievement.title)
                        .font(.system(size: compact ? 24 : 30, weight: .black, design: .serif))

                    Text(achievement.detail)
                        .font(.system(size: compact ? 12 : 14, design: .serif))
                        .multilineTextAlignment(.center)

                    Button(action: onNext) {
                        Text(hasMoreAchievements ? "Next Achievement" : "View Battle Results")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: compact ? 36 : 43)
                            .background(AppTheme.darkBrown, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .foregroundStyle(AppTheme.darkBrown)
                .padding(.horizontal, compact ? 25 : 32)
                .padding(.vertical, compact ? 13 : 23)
                .frame(maxWidth: 440)
                .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 24))
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(AppTheme.darkBrown, lineWidth: 2)
                }
                .shadow(color: .black.opacity(0.25), radius: 18, y: 7)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.85)))
    }
}

// MARK: - Move Inspect Overlay

// Uses IdiotMoveCardView from TeammateCardView.swift.
struct MoveInspectOverlayView: View {
    @ObservedObject var teammate: Teammate
    let onDismiss: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.65)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onDismiss()
                    }

                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(teammate.headImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)

                        Text("\(teammate.name)'s Possible Moves")
                            .font(.system(size: 16, weight: .black, design: .serif))
                            .foregroundStyle(AppTheme.darkBrown)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppTheme.lightTan, in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(AppTheme.darkBrown, lineWidth: 2)
                    }

                    HStack(spacing: 16) {
                        IdiotMoveCardView(card: teammate.optionA)
                            .shadow(color: .black.opacity(0.35), radius: 8, y: 4)

                        IdiotMoveCardView(card: teammate.optionB)
                            .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
                    }
                    .frame(
                        maxWidth: min(460, geometry.size.width - 32),
                        maxHeight: min(280, geometry.size.height * 0.62)
                    )
                    .onTapGesture {}

                    Text("Tap outside to close")
                        .font(.caption.bold())
                        .foregroundStyle(Color.white.opacity(0.9))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.45), in: Capsule())
                }
                .padding()
            }
        }
    }
}

// MARK: - Pause Overlay

struct PauseOverlayView: View {
    let compact: Bool
    let onResume: () -> Void
    let onOpenSettings: () -> Void
    let onOpenHowToPlay: () -> Void
    let onRequestExit: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.56)
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: compact ? 9 : 15) {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: compact ? 27 : 36))

                        Text("Game Paused")
                            .font(.system(size: compact ? 25 : 29, weight: .bold, design: .serif))

                        Text("Even heroes need a break.")
                            .font(.system(size: 13, design: .serif))
                            .italic()
                            .foregroundStyle(AppTheme.darkBrown.opacity(0.7))

                        menuButton("Resume Game", icon: "play.fill", prominent: true, action: onResume)
                        menuButton("Settings", icon: "gearshape.fill", action: onOpenSettings)
                        menuButton("How to Play", icon: "book.closed.fill", action: onOpenHowToPlay)
                        menuButton("Return Home", icon: "house.fill", action: onRequestExit)
                    }
                    .foregroundStyle(AppTheme.darkBrown)
                    .padding(compact ? 15 : 22)
                    .frame(maxWidth: 420)
                    .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 20))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppTheme.darkBrown, lineWidth: 2)
                    }
                    .shadow(color: .black.opacity(0.2), radius: 15, y: 8)
                    .padding(12)
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: min(520, geometry.size.width), maxHeight: geometry.size.height)
            }
        }
    }

    private func menuButton(
        _ title: String,
        icon: String,
        prominent: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .frame(width: 23)

                Text(title)
                    .font(.system(size: compact ? 14 : 16, weight: .semibold))

                Spacer(minLength: 4)

                if !prominent {
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                }
            }
            .foregroundStyle(prominent ? Color.white : AppTheme.darkBrown)
            .padding(.horizontal, 15)
            .frame(height: compact ? 40 : 49)
            .background(
                prominent ? AppTheme.darkBrown : AppTheme.backgroundTan,
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.darkBrown.opacity(prominent ? 0 : 0.4), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
