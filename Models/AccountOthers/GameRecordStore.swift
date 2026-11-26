//
//  GameRecordStore.swift
//  IDSN533 MyHealerSuck
//
//  Account-only battle history with local caching and Cloud Firestore sync.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

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
    @Published private(set) var syncError: String?

    private var loadedUserID: String?
    private var listenerUserID: String?
    private var battleUserID: String?
    private var battleIsGuest = true

    private var battleListener: ListenerRegistration?
    private var uploadedOrQueuedIDs: Set<UUID> = []

    private init() {}

    // MARK: - Identity

    private func currentAccountUID() -> String? {
        guard UserDefaults.standard.string(forKey: "entryMode") == "account",
              let user = Auth.auth().currentUser,
              user.isEmailVerified else {
            return nil
        }
        return user.uid
    }

    private func localStorageKey(for uid: String) -> String {
        "myHealerSucks.completedBattles.account.\(uid).v1"
    }

    // MARK: - Battle Ownership

    func beginBattleSession() {
        // Lock the identity at the beginning of the battle.
        battleUserID = currentAccountUID()
        battleIsGuest = battleUserID == nil
        refreshForCurrentAccount()
    }

    func endBattleSession() {
        battleUserID = nil
        battleIsGuest = true
    }

    // MARK: - Local + Cloud Loading

    func refreshForCurrentAccount() {
        let uid = currentAccountUID()

        // Clear the previous identity's visible data before loading another.
        if loadedUserID != uid {
            stopListening()
            loadedUserID = uid
            uploadedOrQueuedIDs.removeAll()
            syncError = nil
            battles = []

            if let uid,
               let stored = UserDefaults.standard.data(forKey: localStorageKey(for: uid)),
               let saved = try? JSONDecoder().decode([SavedBattle].self, from: stored) {
                battles = sortedUnique(saved)
            }
        }

        guard let uid else {
            stopListening()
            battles = []
            return
        }

        // Even if the identity is unchanged, start listening if needed.
        if listenerUserID != uid {
            startListening(for: uid)
        }
    }

    private func startListening(for uid: String) {
        stopListening()
        listenerUserID = uid

        battleListener = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("battles")
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    guard let self,
                          self.loadedUserID == uid,
                          self.currentAccountUID() == uid else { return }

                    if let error {
                        self.syncError = error.localizedDescription
                        return
                    }

                    guard let snapshot else { return }
                    self.syncError = nil

                    let remote = snapshot.documents.compactMap { document -> SavedBattle? in
                        let data = document.data()
                        guard let id = UUID(uuidString: document.documentID),
                              let timestamp = data["date"] as? Timestamp,
                              let didWin = data["didWin"] as? Bool,
                              let rounds = data["rounds"] as? Int,
                              let survivors = data["survivors"] as? Int else {
                            return nil
                        }
                        return SavedBattle(
                            id: id,
                            date: timestamp.dateValue(),
                            didWin: didWin,
                            rounds: rounds,
                            survivors: survivors
                        )
                    }

                    // Merge by battle ID; never replace existing local history
                    // with an empty or incomplete network snapshot.
                    let remoteIDs = Set(remote.map(\.id))
                    let localOnly = self.battles.filter { !remoteIDs.contains($0.id) }
                    self.battles = self.sortedUnique(remote + localOnly)
                    self.persistLocally(for: uid)

                    // Upload earlier on-device battles using their original IDs.
                    for battle in localOnly {
                        self.queueUpload(battle, for: uid)
                    }
                }
            }

        // Upload existing local results even when an offline cache is empty.
        for battle in battles {
            queueUpload(battle, for: uid)
        }
    }

    private func stopListening() {
        battleListener?.remove()
        battleListener = nil
        listenerUserID = nil
    }

    // MARK: - Recording

    func record(didWin: Bool, rounds: Int, survivingIdiots: Int) {
        // A guest battle can NEVER become an account battle after sign-up.
        guard !battleIsGuest,
              let uid = battleUserID,
              currentAccountUID() == uid else { return }

        refreshForCurrentAccount()
        guard loadedUserID == uid else { return }

        let battle = SavedBattle(
            id: UUID(),
            date: Date(),
            didWin: didWin,
            rounds: max(1, rounds),
            survivors: max(0, survivingIdiots)
        )

        battles = sortedUnique([battle] + battles)
        persistLocally(for: uid)
        queueUpload(battle, for: uid)
    }

    private func queueUpload(_ battle: SavedBattle, for uid: String) {
        guard currentAccountUID() == uid,
              !uploadedOrQueuedIDs.contains(battle.id) else { return }

        uploadedOrQueuedIDs.insert(battle.id)

        let document = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("battles")
            .document(battle.id.uuidString)

        let payload: [String: Any] = [
            "date": Timestamp(date: battle.date),
            "didWin": battle.didWin,
            "rounds": battle.rounds,
            "survivors": battle.survivors
        ]

        // Firestore queues writes while offline; the local copy is already saved.
        document.setData(payload) { [weak self] error in
            Task { @MainActor [weak self] in
                guard let self,
                      self.loadedUserID == uid else { return }
                if let error {
                    self.uploadedOrQueuedIDs.remove(battle.id)
                    self.syncError = error.localizedDescription
                }
            }
        }
    }

    private func persistLocally(for uid: String) {
        guard currentAccountUID() == uid,
              loadedUserID == uid,
              let data = try? JSONEncoder().encode(battles) else { return }
        UserDefaults.standard.set(data, forKey: localStorageKey(for: uid))
    }

    private func sortedUnique(_ input: [SavedBattle]) -> [SavedBattle] {
        var seen = Set<UUID>()
        return input
            .sorted { $0.date > $1.date }
            .filter { seen.insert($0.id).inserted }
    }

    // MARK: - Statistics

    var gamesPlayed: Int { battles.count }
    var victories: Int { battles.filter(\.didWin).count }
    var defeats: Int { gamesPlayed - victories }

    var winRate: Double? {
        guard gamesPlayed > 0 else { return nil }
        return Double(victories) / Double(gamesPlayed)
    }

    // Achievements are derived from synchronized battle history.
    func isUnlocked(_ achievement: BattleAchievement) -> Bool {
        switch achievement {
        case .firstVictory:
            return victories >= 1
        case .luckyEscape:
            return battles.contains { $0.didWin && $0.survivors == 2 }
        case .perfectBabysitter:
            return battles.contains { $0.didWin && $0.survivors == 3 }
        case .persistentHealer:
            return gamesPlayed >= 10
        }
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
        case .firstVictory: return "First Victory"
        case .luckyEscape: return "Lucky Escape"
        case .perfectBabysitter: return "Perfect Babysitter"
        case .persistentHealer: return "Persistent Healer"
        }
    }

    var detail: String {
        switch self {
        case .firstVictory: return "Defeat Bonk for the first time"
        case .luckyEscape: return "Win with exactly two Idiots alive"
        case .perfectBabysitter: return "Win with all three Idiots alive"
        case .persistentHealer: return "Complete 10 battles"
        }
    }

    var icon: String {
        switch self {
        case .firstVictory: return "trophy.fill"
        case .luckyEscape: return "shield.lefthalf.filled"
        case .perfectBabysitter: return "heart.fill"
        case .persistentHealer: return "star.fill"
        }
    }
}

