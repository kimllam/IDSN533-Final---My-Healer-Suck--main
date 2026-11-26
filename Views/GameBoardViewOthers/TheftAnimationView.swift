//
//  TheftAnimationView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/25/26.
//
import SwiftUI

enum TheftAnchor: Hashable {
    case hand(HealerCard)
    case panel(UUID)
}

struct TheftAnchors: PreferenceKey {
    static var defaultValue: [TheftAnchor: Anchor<CGRect>] { [:] }
    static func reduce(
        value: inout [TheftAnchor: Anchor<CGRect>],
        nextValue: () -> [TheftAnchor: Anchor<CGRect>]
    ) {
        value.merge(nextValue()) { _, new in new }
    }
}

struct BoardGhostFlight: View {
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
                .resizable()
                .scaledToFit()
                .frame(width: lands ? 38 : hand.width, height: lands ? 50 : hand.height)
                .rotationEffect(.degrees(lands ? -8 : 0))
                .grayscale(lands ? 1 : 0)
                .opacity(lands ? 0.48 : 1)
                .position(
                    x: lands ? panel.midX : hand.midX,
                    y: lands ? panel.midY + 17 : hand.midY
                )

            Image("ghost")
                .resizable()
                .scaledToFit()
                .frame(width: 102)
                .scaleEffect(appears || reduceMotion ? 1 : 0.8)
                .opacity(appears ? 1 : 0)
                .position(
                    x: lands ? panel.midX : hand.midX - (grips ? 17 : 35),
                    y: lands ? panel.midY - 12 : hand.midY - (grips ? 18 : 38)
                )

            Image(systemName: "sparkle")
                .font(.title2.bold())
                .foregroundStyle(.yellow)
                .shadow(color: .brown, radius: 1)
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
            } catch {
                // Leaving the board cancels this presentation.
            }
        }
    }
}
