//
//  PlayerProfileView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Jingyi on 11/15/26.
//

import SwiftUI
import PhotosUI
import UIKit
import FirebaseAuth

// MARK: - Existing Game Palette

private enum ProfileStyle {
    static let background = Color(
        red: 252/255, green: 220/255, blue: 187/255
    )
    static let paper = Color(
        red: 255/255, green: 243/255, blue: 228/255
    )
    static let brown = Color(
        red: 89/255, green: 59/255, blue: 46/255
    )
    static let line = Color(
        red: 190/255, green: 151/255, blue: 119/255
    )

    static func title(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .serif)
    }
}

// MARK: - Local Image Handling

enum AvatarFile {
    static func url(for scope: String) -> URL? {
        FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first?
            .appendingPathComponent(
                "PlayerProfile",
                isDirectory: true
            )
            .appendingPathComponent("avatar_\(scope).jpg")
    }

    static func load(for scope: String) -> UIImage? {
        guard let url = url(for: scope) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    static func save(_ image: UIImage, for scope: String) throws {
        guard let url = url(for: scope) else {
            throw CocoaError(.fileNoSuchFile)
        }

        let maxDimension = max(
            image.size.width,
            image.size.height
        )

        guard maxDimension > 0 else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let ratio = min(1, 800 / maxDimension)

        let size = CGSize(
            width: image.size.width * ratio,
            height: image.size.height * ratio
        )

        let data = UIGraphicsImageRenderer(
            size: size
        ).jpegData(
            withCompressionQuality: 0.8
        ) { _ in
            image.draw(
                in: CGRect(origin: .zero, size: size)
            )
        }

        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        try data.write(
            to: url,
            options: .atomic
        )
    }
}

// MARK: - Avatar Component

private struct AvatarBadge: View {
    let choice: String
    let photo: UIImage?
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(ProfileStyle.background)

            if choice == "photo", let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: size,
                        height: size
                    )
                    .clipped()
            } else {
                Image(
                    choice == "photo"
                    ? "healer card"
                    : choice
                )
                .resizable()
                .scaledToFit()
                .padding(5)
            }
        }
        .frame(width: size, height: size)
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
    }
}

// MARK: - Navigation Row

private struct PaperRow: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(
                    .system(
                        size: 19,
                        weight: .semibold
                    )
                )
                .frame(width: 26)

            Text(title)
                .font(
                    .system(
                        size: 16,
                        weight: .semibold
                    )
                )

            Spacer()

            Image(systemName: "chevron.right")
                .font(
                    .system(
                        size: 13,
                        weight: .bold
                    )
                )
        }
        .foregroundStyle(ProfileStyle.brown)
        .padding(.horizontal, 17)
        .frame(height: 62)
        .background(
            ProfileStyle.paper,
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    ProfileStyle.line,
                    lineWidth: 1.3
                )
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Main Player Profile

struct PlayerProfileView: View {
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var game: GameManager
    @EnvironmentObject private var appRoute: AppRouteState

    @AppStorage("entryMode") private var entryMode = ""

    // Guest and registered account have different exit semantics.
    private var isGuest: Bool {
        entryMode != "account" || !auth.isLoggedIn || !auth.isEmailVerified
    }

    private var playerIdentityLabel: String {
        if isGuest {
            return "Guest Player"
        }
        if let email = Auth.auth().currentUser?.email, !email.isEmpty {
            return email
        }
        return "Registered Player"
    }

    // Keep guest and registered account nicknames separate.
    @State private var nickname = ""

    private var nicknameStorageKey: String {
        if isGuest {
            return "playerNickname.guest"
        }
        return "playerNickname.account.\(auth.userID ?? "unknown")"
    }

    private func loadNickname() {
        // Do not migrate the old shared nickname into an account.
        nickname = UserDefaults.standard.string(
            forKey: nicknameStorageKey
        ) ?? ""
    }

    @State private var avatarChoice = "healer card"

    private var avatarScope: String {
        isGuest ? "guest" : (auth.userID ?? "unknown")
    }

    private var avatarChoiceKey: String {
        "playerAvatarChoice.\(avatarScope)"
    }

    private func loadAvatarSettings() {
        // Read only the current identity's avatar and picture.
        avatarChoice = UserDefaults.standard.string(
            forKey: avatarChoiceKey
        ) ?? "healer card"
        avatarPhoto = AvatarFile.load(for: avatarScope)
    }

    private func connectProfileCloud() {
        guard !isGuest, let uid = auth.userID else {
            cloudProfile.disconnect()
            return
        }
        cloudProfile.connect(
            uid: uid,
            localNickname: nickname,
            localAvatarChoice: avatarChoice
        )
    }

    @Environment(\.dismiss)
    private var dismiss

    @State private var avatarPhoto: UIImage?
    @State private var showSignUpSheet = false
    @State private var signOutErrorMessage: String?
    @StateObject private var records = GameRecordStore.shared
    @StateObject private var cloudProfile = CloudPlayerProfileStore()

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let isLandscape =
                    geometry.size.width > geometry.size.height

                ZStack {
                    ProfileStyle.background
                        .ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 15) {
                            HStack {
                                Text("Player Profile")
                                    .font(
                                        ProfileStyle.title(28)
                                    )

                                Spacer()

                                Button {
                                    dismiss()
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.headline)
                                        .frame(
                                            width: 40,
                                            height: 40
                                        )
                                        .background(
                                            ProfileStyle.paper,
                                            in: Circle()
                                        )
                                        .overlay {
                                            Circle()
                                                .stroke(
                                                    ProfileStyle.line,
                                                    lineWidth: 1.2
                                                )
                                        }
                                }
                                .accessibilityLabel(
                                    "Close profile"
                                )
                            }
                            .padding(.bottom, 4)

                            NavigationLink {
                                EditProfileScreen(
                                    nickname: $nickname,
                                    avatarChoice: $avatarChoice,
                                    avatarPhoto: $avatarPhoto,
                                    avatarScope: avatarScope,
                                    onSaveNickname: { value in
                                        if !isGuest { cloudProfile.saveNickname(value) }
                                    },
                                    onChooseBuiltInAvatar: { choice in
                                        if !isGuest { cloudProfile.saveBuiltInAvatar(choice) }
                                    }
                                )
                            } label: {
                                HStack(spacing: 14) {
                                    AvatarBadge(
                                        choice: avatarChoice,
                                        photo: avatarPhoto,
                                        size: 72
                                    )

                                    VStack(
                                        alignment: .leading,
                                        spacing: 5
                                    ) {
                                        Text(
                                            nickname.isEmpty
                                            ? "Healer"
                                            : nickname
                                        )
                                        .font(
                                            ProfileStyle.title(22)
                                        )
                                        .lineLimit(1)

                                        Text(playerIdentityLabel)
                                            .font(.caption)
                                            .lineLimit(1)
                                            .foregroundStyle(
                                                ProfileStyle.brown
                                                    .opacity(0.72)
                                            )
                                    }

                                    Spacer(minLength: 4)

                                    Image(
                                        systemName: "chevron.right"
                                    )
                                    .font(.caption.bold())
                                }
                                .foregroundStyle(
                                    ProfileStyle.brown
                                )
                                .padding(14)
                                .background(
                                    ProfileStyle.paper,
                                    in: RoundedRectangle(
                                        cornerRadius: 15
                                    )
                                )
                                .overlay {
                                    RoundedRectangle(
                                        cornerRadius: 15
                                    )
                                    .stroke(
                                        ProfileStyle.line,
                                        lineWidth: 1.3
                                    )
                                }
                            }
                            .buttonStyle(.plain)

                            if isGuest {
                                Button {
                                    showSignUpSheet = true
                                } label: {
                                    PaperRow(
                                        title: "Create Account / Log In",
                                        icon: "person.badge.plus"
                                    )
                                }
                                .buttonStyle(.plain)
                            } else {
                                NavigationLink {
                                    BattleStatisticsScreen(
                                        records: records
                                    )
                                } label: {
                                    PaperRow(
                                        title: "Game Statistics",
                                        icon: "chart.bar.fill"
                                    )
                                }
                                .buttonStyle(.plain)

                                NavigationLink {
                                    BattleAchievementsScreen(
                                        records: records
                                    )
                                } label: {
                                    PaperRow(
                                        title: "Achievements",
                                        icon: "trophy.fill"
                                    )
                                }
                                .buttonStyle(.plain)

                                Button(action: handleLogOut) {
                                    HStack(spacing: 14) {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .font(
                                                .system(
                                                    size: 19,
                                                    weight: .semibold
                                                )
                                            )
                                            .frame(width: 26)

                                        Text("Log Out")
                                            .font(
                                                .system(
                                                    size: 16,
                                                    weight: .semibold
                                                )
                                            )

                                        Spacer()
                                    }
                                    .foregroundStyle(ProfileStyle.brown)
                                    .padding(.horizontal, 17)
                                    .frame(height: 56)
                                    .background(
                                        ProfileStyle.paper,
                                        in: RoundedRectangle(cornerRadius: 14)
                                    )
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(
                                                ProfileStyle.line,
                                                lineWidth: 1.3
                                            )
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }

                            achievementsPreview
                                .padding(.top, 8)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                        .padding(.bottom, 26)
                        .frame(
                            maxWidth: isLandscape ? 740 : 520
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSignUpSheet) {
                AuthView(
                    mode: .signUp,
                    onAuthenticated: {
                        showSignUpSheet = false
                        dismiss()
                    },
                    onPlayAsGuest: {
                        GameRecordStore.shared.endBattleSession()
                        game.inspectedTeammate = nil
                        game.resetGame()
                        entryMode = "guest"
                        GameRecordStore.shared.refreshForCurrentAccount()
                        showSignUpSheet = false
                    }
                )
                .environmentObject(auth)
                .environmentObject(game)
                .environmentObject(appRoute)
            }
            .alert(
                "Unable to Log Out",
                isPresented: Binding(
                    get: { signOutErrorMessage != nil },
                    set: { if !$0 { signOutErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(signOutErrorMessage ?? "Please try again.")
            }
            .onAppear {
                loadAvatarSettings()
                loadNickname()
                if !isGuest {
                    records.refreshForCurrentAccount()
                }
                connectProfileCloud()
            }
            .onChange(of: avatarChoice) { _, value in
                UserDefaults.standard.set(value, forKey: avatarChoiceKey)
            }
            .onChange(of: nickname) { _, value in
                UserDefaults.standard.set(value, forKey: nicknameStorageKey)
            }
            .onChange(of: cloudProfile.remoteNickname) { _, value in
                guard !isGuest, cloudProfile.activeUID == auth.userID,
                      let value else { return }
                nickname = value
            }
            .onChange(of: cloudProfile.remoteAvatarChoice) { _, value in
                guard !isGuest, cloudProfile.activeUID == auth.userID,
                      let value else { return }
                // A local personal photo takes precedence on this device.
                if avatarChoice == "photo", avatarPhoto != nil { return }
                avatarChoice = value
            }
            .onChange(of: entryMode) { _, _ in
                loadNickname()
                loadAvatarSettings()
                connectProfileCloud()
            }
            .onChange(of: auth.userID) { _, _ in
                loadNickname()
                loadAvatarSettings()
                connectProfileCloud()
            }
            .onChange(of: auth.isEmailVerified) { _, _ in
                connectProfileCloud()
            }
        }
        .tint(ProfileStyle.brown)
        .onDisappear {
            // Keep syncing while navigating to Edit Profile.
            // Disconnect only when this profile flow is dismissed.
            cloudProfile.disconnect()
        }
    }

    private func handleLogOut() {
        do {
            cloudProfile.disconnect()
            GameRecordStore.shared.endBattleSession()
            game.inspectedTeammate = nil
            game.resetGame()
            try Auth.auth().signOut()
            entryMode = ""
            GameRecordStore.shared.refreshForCurrentAccount()
            dismiss()
        } catch {
            signOutErrorMessage = error.localizedDescription
        }
    }

    // MARK: - Achievements Preview

    private var achievementsPreview: some View {
        let earned = BattleAchievement.allCases.filter { records.isUnlocked($0) }

        return VStack(spacing: 12) {
            HStack(spacing: 10) {
                Rectangle()
                    .fill(ProfileStyle.line)
                    .frame(height: 1)

                Text(isGuest ? "ACHIEVEMENTS" : "EARNED ACHIEVEMENTS")
                    .font(ProfileStyle.title(13))
                    .tracking(1)
                    .fixedSize()

                Rectangle()
                    .fill(ProfileStyle.line)
                    .frame(height: 1)
            }
            .padding(.horizontal, 6)

            if isGuest {
                HStack(spacing: 14) {
                    ForEach(BattleAchievement.allCases) { achievement in
                        ZStack {
                            Image(systemName: achievement.icon)
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(ProfileStyle.brown)
                                .frame(width: 48, height: 48)
                                .background(
                                    ProfileStyle.background,
                                    in: Circle()
                                )
                                .opacity(0.32)

                            Image(systemName: "lock.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(ProfileStyle.brown)
                                .padding(5)
                                .background(
                                    ProfileStyle.paper,
                                    in: Circle()
                                )
                                .overlay {
                                    Circle()
                                        .stroke(ProfileStyle.line, lineWidth: 1)
                                }
                                .offset(x: 15, y: 15)
                        }
                    }
                }
                .padding(.vertical, 4)

                Text("Log in and earn these trophies.")
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .italic()
                    .multilineTextAlignment(.center)
            } else if earned.isEmpty {
                HStack(spacing: 14) {
                    ForEach(BattleAchievement.allCases) { achievement in
                        Image(systemName: achievement.icon)
                            .font(.system(size: 24))
                            .foregroundStyle(ProfileStyle.brown.opacity(0.3))
                            .frame(width: 44, height: 44)
                            .background(ProfileStyle.background, in: Circle())
                    }
                }

                Text("No trophies earned yet—win battles to unlock them.")
                    .font(.system(size: 14, design: .serif))
                    .italic()
                    .multilineTextAlignment(.center)
            } else {
                HStack(spacing: 14) {
                    ForEach(earned) { achievement in
                        VStack(spacing: 6) {
                            Image(systemName: achievement.icon)
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(ProfileStyle.brown)
                                .frame(width: 48, height: 48)
                                .background(
                                    ProfileStyle.background,
                                    in: Circle()
                                )
                                .overlay {
                                    Circle()
                                        .stroke(ProfileStyle.line, lineWidth: 1.2)
                                }

                            Text(achievement.title)
                                .font(.caption2.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                Text("\(earned.count) of \(BattleAchievement.allCases.count) trophies unlocked")
                    .font(.system(size: 13, design: .serif))
                    .italic()
            }
        }
        .foregroundStyle(ProfileStyle.brown.opacity(0.85))
        .padding(.horizontal, 14)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(
            ProfileStyle.paper.opacity(0.58),
            in: RoundedRectangle(cornerRadius: 22)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    ProfileStyle.line.opacity(0.65),
                    lineWidth: 1.1
                )
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Edit Profile

private struct EditProfileScreen: View {
    @Binding var nickname: String
    @Binding var avatarChoice: String
    @Binding var avatarPhoto: UIImage?
    let avatarScope: String
    let onSaveNickname: (String) -> Void
    let onChooseBuiltInAvatar: (String) -> Void

    @State private var draft = ""
    @State private var saved = false

    @FocusState private var focused: Bool

    private var cleaned: String {
        String(
            draft.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .prefix(20)
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Edit Profile")
                    .font(ProfileStyle.title(26))
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )

                NavigationLink {
                    ChooseAvatarScreen(
                        choice: $avatarChoice,
                        photo: $avatarPhoto,
                        avatarScope: avatarScope,
                        onChooseBuiltInAvatar: onChooseBuiltInAvatar
                    )
                } label: {
                    VStack(spacing: 8) {
                        AvatarBadge(
                            choice: avatarChoice,
                            photo: avatarPhoto,
                            size: 104
                        )

                        Label(
                            "Change Avatar",
                            systemImage: "camera.fill"
                        )
                        .font(.subheadline.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(
                        ProfileStyle.paper,
                        in: RoundedRectangle(
                            cornerRadius: 15
                        )
                    )
                }
                .buttonStyle(.plain)

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {
                    Text("PLAYER NAME")
                        .font(.headline)

                    TextField(
                        "Enter nickname",
                        text: $draft
                    )
                    .focused($focused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .onChange(of: draft) {
                        _, newValue in

                        if newValue.count > 20 {
                            draft = String(
                                newValue.prefix(20)
                            )
                        }

                        saved = false
                    }
                    .padding(12)
                    .background(
                        .white,
                        in: RoundedRectangle(
                            cornerRadius: 10
                        )
                    )

                    Text("\(draft.count)/20")
                        .font(.caption)
                        .frame(
                            maxWidth: .infinity,
                            alignment: .trailing
                        )

                    Button {
                        guard !cleaned.isEmpty else {
                            return
                        }

                        nickname = cleaned
                        draft = cleaned
                        focused = false
                        onSaveNickname(cleaned)
                        saved = true

                    } label: {
                        Text("Save Nickname")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(13)
                            .foregroundStyle(.white)
                            .background(
                                cleaned.isEmpty
                                ? .gray
                                : ProfileStyle.brown,
                                in: RoundedRectangle(
                                    cornerRadius: 11
                                )
                            )
                    }
                    .disabled(cleaned.isEmpty)

                    if saved {
                        Label(
                            "Nickname saved",
                            systemImage: "checkmark.circle.fill"
                        )
                        .font(.caption)
                    }
                }
                .padding(16)
                .background(
                    ProfileStyle.paper,
                    in: RoundedRectangle(cornerRadius: 15)
                )
            }
            .foregroundStyle(ProfileStyle.brown)
            .padding(20)
            .frame(maxWidth: 530)
            .frame(maxWidth: .infinity)
        }
        .background(
            ProfileStyle.background.ignoresSafeArea()
        )
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .onAppear {
            draft = nickname
        }
    }
}

// MARK: - Choose Avatar

private struct ChooseAvatarScreen: View {
    @Binding var choice: String
    @Binding var photo: UIImage?
    let avatarScope: String
    let onChooseBuiltInAvatar: (String) -> Void

    @Environment(\.dismiss)
    private var dismiss

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var failed = false

    private let choices = [
        ("healer card", "Healer"),
        ("knight head", "Knight"),
        ("vampire head", "Vampire"),
        ("boom head", "Dr. Boom Boom")
    ]

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 18
            ) {
                Text("Choose Your Avatar")
                    .font(ProfileStyle.title(24))

                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: 12
                ) {
                    ForEach(
                        choices.indices,
                        id: \.self
                    ) { index in

                        let asset = choices[index].0
                        let title = choices[index].1

                        Button {
                            choice = asset
                            onChooseBuiltInAvatar(asset)
                            dismiss()

                        } label: {
                            VStack(spacing: 10) {
                                Image(asset)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 105)

                                Text(title)
                                    .font(.subheadline.bold())

                                if choice == asset {
                                    Image(
                                        systemName:
                                            "checkmark.circle.fill"
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(
                                ProfileStyle.paper,
                                in: RoundedRectangle(
                                    cornerRadius: 13
                                )
                            )
                            .overlay {
                                RoundedRectangle(
                                    cornerRadius: 13
                                )
                                .stroke(
                                    choice == asset
                                    ? ProfileStyle.brown
                                    : ProfileStyle.line,
                                    lineWidth:
                                        choice == asset ? 2 : 1
                                )
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images
                ) {
                    Label(
                        "Choose from Photos",
                        systemImage: "photo.on.rectangle"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .foregroundStyle(.white)
                    .background(
                        ProfileStyle.brown,
                        in: RoundedRectangle(
                            cornerRadius: 12
                        )
                    )
                }
                .buttonStyle(.plain)

                Text("Personal photos remain on this device.")
                    .font(.caption)
                    .foregroundStyle(
                        ProfileStyle.brown.opacity(0.7)
                    )
            }
            .foregroundStyle(ProfileStyle.brown)
            .padding(20)
            .frame(maxWidth: 530)
            .frame(maxWidth: .infinity)
        }
        .background(
            ProfileStyle.background.ignoresSafeArea()
        )
        .navigationTitle("Avatar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .onChange(of: selectedPhoto) {
            _, item in

            guard let item else { return }

            Task {
                await importPhoto(item)
            }
        }
        .alert(
            "Unable to Save Photo",
            isPresented: $failed
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please select a different photo.")
        }
    }

    @MainActor
    private func importPhoto(
        _ item: PhotosPickerItem
    ) async {
        do {
            guard let data =
                    try await item.loadTransferable(
                        type: Data.self
                    ),
                  let image = UIImage(data: data)
            else {
                failed = true
                return
            }

            try AvatarFile.save(image, for: avatarScope)

            photo = AvatarFile.load(for: avatarScope)
            choice = "photo"
            selectedPhoto = nil
            dismiss()

        } catch {
            failed = true
        }
    }
}

// MARK: - Battle Statistics

private struct BattleStatisticsScreen: View {
    @ObservedObject var records: GameRecordStore

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 18
            ) {
                Text("Battle Statistics")
                    .font(ProfileStyle.title(27))

                LazyVGrid(
                    columns: columns,
                    spacing: 12
                ) {
                    statistic(
                        "Battles Played",
                        value: "\(records.gamesPlayed)",
                        icon: "swords"
                    )

                    statistic(
                        "Victories",
                        value: "\(records.victories)",
                        icon: "trophy.fill"
                    )

                    statistic(
                        "Defeats",
                        value: "\(records.defeats)",
                        icon: "xmark.shield.fill"
                    )

                    statistic(
                        "Win Rate",
                        value: records.winRate.map {
                            "\(Int(($0 * 100).rounded()))%"
                        } ?? "—",
                        icon: "chart.bar.fill"
                    )
                }

                Text("Recent Battles")
                    .font(ProfileStyle.title(19))

                if records.battles.isEmpty {
                    Text(
                        "No completed battles yet. Finish a game to see your first result."
                    )
                    .font(.subheadline)
                    .foregroundStyle(
                        ProfileStyle.brown.opacity(0.76)
                    )
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(17)
                    .background(
                        ProfileStyle.paper,
                        in: RoundedRectangle(
                            cornerRadius: 14
                        )
                    )

                } else {
                    ForEach(
                        Array(records.battles.prefix(5))
                    ) { battle in
                        HStack {
                            Image(
                                systemName: battle.didWin
                                ? "trophy.fill"
                                : "shield.slash.fill"
                            )

                            VStack(
                                alignment: .leading,
                                spacing: 4
                            ) {
                                Text(
                                    battle.didWin
                                    ? "Victory"
                                    : "Defeat"
                                )
                                .font(.headline)

                                Text(
                                    battle.date,
                                    style: .date
                                )
                                .font(.caption)
                            }

                            Spacer()

                            Text(
                                "\(battle.rounds) rounds"
                            )
                            .font(.subheadline)
                        }
                        .padding(14)
                        .background(
                            ProfileStyle.paper,
                            in: RoundedRectangle(
                                cornerRadius: 13
                            )
                        )
                    }
                }
            }
            .foregroundStyle(ProfileStyle.brown)
            .padding(20)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(
            ProfileStyle.background.ignoresSafeArea()
        )
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }

    private func statistic(
        _ label: String,
        value: String,
        icon: String
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 14
        ) {
            HStack {
                Text(label)
                    .font(.caption)

                Spacer()

                Image(systemName: icon)
            }

            Text(value)
                .font(ProfileStyle.title(30))
        }
        .padding(16)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            ProfileStyle.paper,
            in: RoundedRectangle(
                cornerRadius: 14
            )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    ProfileStyle.line,
                    lineWidth: 1
                )
        }
    }
}

// MARK: - Achievements

private struct BattleAchievementsScreen: View {
    @ObservedObject var records: GameRecordStore

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 16
            ) {
                Text("Achievements")
                    .font(ProfileStyle.title(27))

                Text(
                    "\(BattleAchievement.allCases.filter { records.isUnlocked($0) }.count) / 4 unlocked"
                )
                .font(.subheadline)

                LazyVGrid(
                    columns: columns,
                    spacing: 12
                ) {
                    ForEach(
                        BattleAchievement.allCases
                    ) { achievement in

                        let unlocked =
                            records.isUnlocked(achievement)

                        VStack(spacing: 11) {
                            Image(
                                systemName: achievement.icon
                            )
                            .font(.system(size: 30))
                            .foregroundStyle(
                                unlocked
                                ? ProfileStyle.brown
                                : ProfileStyle.line
                            )
                            .frame(height: 44)

                            Text(achievement.title)
                                .font(
                                    .system(
                                        size: 15,
                                        weight: .bold,
                                        design: .serif
                                    )
                                )
                                .multilineTextAlignment(.center)

                            Text(achievement.detail)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(
                                    ProfileStyle.brown
                                        .opacity(0.72)
                                )
                                .fixedSize(
                                    horizontal: false,
                                    vertical: true
                                )

                            Label(
                                unlocked
                                ? "Unlocked"
                                : "Locked",
                                systemImage: unlocked
                                ? "checkmark.seal.fill"
                                : "lock.fill"
                            )
                            .font(.caption.bold())
                        }
                        .foregroundStyle(ProfileStyle.brown)
                        .frame(
                            maxWidth: .infinity,
                            minHeight: 170
                        )
                        .padding(12)
                        .background(
                            ProfileStyle.paper,
                            in: RoundedRectangle(
                                cornerRadius: 14
                            )
                        )
                        .overlay {
                            RoundedRectangle(
                                cornerRadius: 14
                            )
                            .stroke(
                                ProfileStyle.line,
                                lineWidth: 1
                            )
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(
            ProfileStyle.background.ignoresSafeArea()
        )
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

#Preview {
    PlayerProfileView()
        .environmentObject(GameManager())
        .environmentObject(AuthManager())
        .environmentObject(AppRouteState())
}
