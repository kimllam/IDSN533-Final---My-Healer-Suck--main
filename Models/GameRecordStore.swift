//
//  GameRecordStore.swift
//  IDSN533 MyHealerSuck
//
//  Created by Jingyi on 11/15/26.
//


import Foundation
import Combine

// Stores completed battle results locally, without Firebase or an account.
struct SavedBattle: Codable, Identifiable {
    var id: UUID
    var date: Date
    var didWin: Bool
    var rounds: Int
    var survivors: Int
}

@MainActor
final class GameRecordStore: ObservableObject {
    static let shared = GameRecordStore()

    @Published private(set) var battles: [SavedBattle] = []
    private let storageKey = "myHealerSucks.completedBattles.v1"

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([SavedBattle].self, from: data) {
            battles = saved
        }
    }

    var gamesPlayed: Int { battles.count }
    var victories: Int { battles.filter(\.didWin).count }
    var defeats: Int { gamesPlayed - victories }

    var winRate: Double? {
        guard gamesPlayed > 0 else { return nil }
        return Double(victories) / Double(gamesPlayed)
    }

    func record(
        didWin: Bool,
        rounds: Int,
        survivingIdiots: Int
    ) {
        let result = SavedBattle(
            id: UUID(),
            date: Date(),
            didWin: didWin,
            rounds: max(1, rounds),
            survivors: max(0, survivingIdiots)
        )

        battles.insert(result, at: 0)
        persist()
    }

    func isUnlocked(_ achievement: BattleAchievement) -> Bool {
        switch achievement {
        case .firstVictory:
            return victories >= 1

        case .luckyEscape:
            return battles.contains {
                $0.didWin && $0.survivors == 2
            }

        case .perfectBabysitter:
            return battles.contains {
                $0.didWin && $0.survivors == 3
            }

        case .persistentHealer:
            return gamesPlayed >= 10
        }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(battles)
        else { return }

        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

enum BattleAchievement: String, CaseIterable, Identifiable {
    case firstVictory
    case luckyEscape
    case perfectBabysitter
    case persistentHealer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstVictory:
            return "First Victory"
        case .luckyEscape:
            return "Lucky Escape"
        case .perfectBabysitter:
            return "Perfect Babysitter"
        case .persistentHealer:
            return "Persistent Healer"
        }
    }

    var detail: String {
        switch self {
        case .firstVictory:
            return "Defeat Bonk for the first time"
        case .luckyEscape:
            return "Win with exactly two Idiots alive"
        case .perfectBabysitter:
            return "Win with all three Idiots alive"
        case .persistentHealer:
            return "Complete 10 battles"
        }
    }

    var icon: String {
        switch self {
        case .firstVictory:
            return "trophy.fill"
        case .luckyEscape:
            return "shield.lefthalf.filled"
        case .perfectBabysitter:
            return "heart.fill"
        case .persistentHealer:
            return "star.fill"
        }
    }
}

