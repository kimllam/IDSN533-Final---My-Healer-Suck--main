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
    let onClose: () -> Void
    let onResume: () -> Void
    let onOpenProfile: () -> Void
    let onOpenSettings: () -> Void
    let onOpenHowToPlay: () -> Void
    let onRequestExit: () -> Void

    private let softExitText = Color(red: 0.62, green: 0.21, blue: 0.19)
    private let softExitFill = Color(red: 0.96, green: 0.84, blue: 0.82)
    private let softExitBorder = Color(red: 0.78, green: 0.42, blue: 0.39)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.56)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onClose()
                    }

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: compact ? 8 : 13) {
                        HStack {
                            Spacer()

                            Button(action: onClose) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(AppTheme.darkBrown)
                                    .frame(width: 34, height: 34)
                                    .background(AppTheme.backgroundTan, in: Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(AppTheme.darkBrown.opacity(0.45), lineWidth: 1.2)
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Close Pause Menu")
                        }


                        Text("Game Paused")
                            .font(.system(size: compact ? 23 : 28, weight: .bold, design: .serif))

                        Spacer()

                        menuButton("Resume Game", icon: "play.fill", style: .primary, action: onResume)
                        menuButton("Player Profile", icon: "person.crop.circle.fill", action: onOpenProfile)
                        menuButton("Settings", icon: "gearshape.fill", action: onOpenSettings)
                        menuButton("Rulebook", icon: "book.closed.fill", action: onOpenHowToPlay)
                        menuButton("Return Home", icon: "house.fill", style: .destructive, action: onRequestExit)
                    }
                    .foregroundStyle(AppTheme.darkBrown)
                    .padding(compact ? 14 : 20)
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

    private enum MenuButtonStyleKind {
        case standard
        case primary
        case destructive
    }

    private func menuButton(
        _ title: String,
        icon: String,
        style: MenuButtonStyleKind = .standard,
        action: @escaping () -> Void
    ) -> some View {
        let foreground: Color = switch style {
        case .standard: AppTheme.darkBrown
        case .primary: .white
        case .destructive: softExitText
        }

        let fill: Color = switch style {
        case .standard: AppTheme.backgroundTan
        case .primary: AppTheme.darkBrown
        case .destructive: softExitFill
        }

        let borderColor: Color = switch style {
        case .standard: AppTheme.darkBrown.opacity(0.4)
        case .primary: .clear
        case .destructive: softExitBorder
        }

        return Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .frame(width: 23)

                Text(title)
                    .font(.system(size: compact ? 14 : 16, weight: .semibold))

                Spacer(minLength: 4)

                if style == .standard {
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                }
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, 15)
            .frame(height: compact ? 38 : 47)
            .background(fill, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1.2)
            }
        }
        .buttonStyle(.plain)
    }
}
