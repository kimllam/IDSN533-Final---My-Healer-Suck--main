//
//  CloudPlayerProfileStore.swift
//  IDSN533 MyHealerSuck
//
//  Created by Jingyi on 11/20/26.
//

//
//  CloudPlayerProfileStore.swift
//  IDSN533 MyHealerSuck
//
//  Syncs a registered player's nickname and built-in avatar choice.
//  Custom photo files remain on this device.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class CloudPlayerProfileStore: ObservableObject {
    @Published private(set) var remoteNickname: String?
    @Published private(set) var remoteAvatarChoice: String?
    @Published private(set) var isReady = false
    @Published private(set) var syncError: String?

    private(set) var activeUID: String?
    private var listener: ListenerRegistration?
    private var initialNickname = ""
    private var initialAvatarChoice = "healer card"

    private static let builtInAvatars: Set<String> = [
        "healer card", "knight head", "vampire head", "boom head"
    ]

    func connect(
        uid: String,
        localNickname: String,
        localAvatarChoice: String
    ) {
        guard activeUID != uid else { return }
        disconnect()

        activeUID = uid
        initialNickname = localNickname
        initialAvatarChoice = localAvatarChoice

        let document = Firestore.firestore()
            .collection("users")
            .document(uid)

        listener = document.addSnapshotListener { [weak self] snapshot, error in
            Task { @MainActor [weak self] in
                guard let self,
                      self.activeUID == uid,
                      Auth.auth().currentUser?.uid == uid,
                      UserDefaults.standard.string(forKey: "entryMode") == "account" else {
                    return
                }

                if let error {
                    self.syncError = error.localizedDescription
                    return
                }

                guard let snapshot else { return }
                self.syncError = nil

                let data = snapshot.data() ?? [:]

                if let cloudName = data["nickname"] as? String {
                    self.remoteNickname = cloudName
                }

                if let cloudChoice = data["avatarChoice"] as? String,
                   Self.builtInAvatars.contains(cloudChoice) {
                    self.remoteAvatarChoice = cloudChoice
                }

                // Only migrate local values after a confirmed server response.
                // A missing offline-cache document must never overwrite cloud data.
                guard !snapshot.metadata.isFromCache else { return }

                self.isReady = true

                var missingFields: [String: Any] = [:]

                if data["nickname"] == nil, !self.initialNickname.isEmpty {
                    missingFields["nickname"] = self.initialNickname
                }

                if data["avatarChoice"] == nil {
                    missingFields["avatarChoice"] =
                        Self.builtInAvatars.contains(self.initialAvatarChoice)
                        ? self.initialAvatarChoice : "healer card"
                }

                if !missingFields.isEmpty {
                    document.setData(missingFields, merge: true) { [weak self] error in
                        Task { @MainActor [weak self] in
                            guard let self, self.activeUID == uid else { return }
                            if let error {
                                self.syncError = error.localizedDescription
                            }
                        }
                    }
                }
            }
        }
    }

    func saveNickname(_ rawName: String) {
        guard let uid = authorizedUID() else { return }

        let name = String(
            rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                .prefix(20)
        )

        guard !name.isEmpty, name != remoteNickname else { return }

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .setData(["nickname": name], merge: true) { [weak self] error in
                Task { @MainActor [weak self] in
                    guard let self, self.activeUID == uid else { return }
                    if let error {
                        self.syncError = error.localizedDescription
                    }
                }
            }
    }

    func saveBuiltInAvatar(_ choice: String) {
        guard let uid = authorizedUID(),
              Self.builtInAvatars.contains(choice),
              choice != remoteAvatarChoice else { return }

        // Never upload personal photos or a 'photo' placeholder.
        Firestore.firestore()
            .collection("users")
            .document(uid)
            .setData(["avatarChoice": choice], merge: true) { [weak self] error in
                Task { @MainActor [weak self] in
                    guard let self, self.activeUID == uid else { return }
                    if let error {
                        self.syncError = error.localizedDescription
                    }
                }
            }
    }

    private func authorizedUID() -> String? {
        guard let uid = activeUID,
              let user = Auth.auth().currentUser,
              user.uid == uid,
              user.isEmailVerified,
              UserDefaults.standard.string(forKey: "entryMode") == "account" else {
            return nil
        }
        return uid
    }

    func disconnect() {
        listener?.remove()
        listener = nil
        activeUID = nil
        remoteNickname = nil
        remoteAvatarChoice = nil
        isReady = false
        syncError = nil
        initialNickname = ""
        initialAvatarChoice = "healer card"
    }
}
