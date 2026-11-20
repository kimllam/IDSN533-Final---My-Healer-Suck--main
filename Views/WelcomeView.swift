import SwiftUI

// MARK: - Landscape Account Selection

struct WelcomeView: View {
    @AppStorage("entryMode") private var entryMode = ""
    @State private var navigateToGuest = false

    private let background = Color(red: 252/255, green: 220/255, blue: 187/255)
    private let paper = Color(red: 255/255, green: 243/255, blue: 228/255)
    private let brown = Color(red: 89/255, green: 59/255, blue: 46/255)

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let compact = geometry.size.height < 430

            ZStack {
                background.ignoresSafeArea()

                ScrollView(.vertical) {
                    Group {
                        if isLandscape {
                            landscapeSelection(compact: compact)
                        } else {
                            portraitSelection
                        }
                    }
                    .frame(maxWidth: isLandscape ? 770 : 390)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, isLandscape ? 24 : 18)
                    .padding(.vertical, compact ? 12 : 22)
                    .frame(minHeight: geometry.size.height, alignment: .center)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationDestination(isPresented: $navigateToGuest) {
            GameBoardView()
                .navigationBarBackButtonHidden(true)
                .toolbar(.hidden, for: .navigationBar)
        }
        .navigationBarTitleDisplayMode(.inline)
        .tint(brown)
    }

    private func landscapeSelection(compact: Bool) -> some View {
        HStack(spacing: 22) {
            VStack(spacing: compact ? 8 : 12) {
                Image("healer card")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: compact ? 95 : 132)
                    .accessibilityHidden(true)

                Text("Ready to Play?")
                    .font(.system(size: compact ? 25 : 31, weight: .black, design: .serif))
                    .foregroundStyle(brown)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)

                Text("Choose how you'd like to enter the game.")
                    .font(.system(size: compact ? 12 : 14))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(brown.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(brown.opacity(0.18))
                .frame(width: 1)
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: compact ? 9 : 14) {
                Text("PLAY AS")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(brown.opacity(0.7))

                accountOptions(compact: compact)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, compact ? 24 : 30)
        .padding(.vertical, compact ? 16 : 24)
        .background(paper, in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(brown.opacity(0.62), lineWidth: 1.5)
        }
    }

    private var portraitSelection: some View {
        VStack(spacing: 16) {
            Image("healer card")
                .resizable()
                .scaledToFit()
                .frame(height: 112)

            Text("Ready to Play?")
                .font(.system(size: 29, weight: .black, design: .serif))
                .foregroundStyle(brown)

            Text("Choose how you'd like to enter the game.")
                .font(.system(size: 14))
                .foregroundStyle(brown.opacity(0.75))
                .multilineTextAlignment(.center)

            accountOptions(compact: false)
        }
        .padding(24)
        .background(paper, in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(brown.opacity(0.62), lineWidth: 1.5)
        }
    }

    private func accountOptions(compact: Bool) -> some View {
        VStack(spacing: compact ? 9 : 12) {
            Button(action: enterAsGuest) {
                Label("Continue as Guest", systemImage: "gamecontroller.fill")
                    .frame(maxWidth: .infinity)
                    .frame(height: compact ? 43 : 49)
                    .foregroundStyle(.white)
                    .background(brown, in: RoundedRectangle(cornerRadius: 12))
            }

            NavigationLink {
                AuthView(mode: .signUp)
            } label: {
                Label("Create Account", systemImage: "person.badge.plus")
                    .frame(maxWidth: .infinity)
                    .frame(height: compact ? 43 : 49)
                    .foregroundStyle(brown)
                    .background(background, in: RoundedRectangle(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(brown.opacity(0.45), lineWidth: 1)
                    }
            }

            NavigationLink {
                AuthView(mode: .logIn)
            } label: {
                Label("Log In", systemImage: "person.crop.circle")
                    .frame(maxWidth: .infinity)
                    .frame(height: compact ? 43 : 49)
                    .foregroundStyle(brown)
                    .background(paper, in: RoundedRectangle(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(brown.opacity(0.45), lineWidth: 1)
                    }
            }
        }
        .font(.system(size: compact ? 14 : 16, weight: .semibold))
        .buttonStyle(.plain)
    }

    private func enterAsGuest() {
        // Entering as a guest must not reuse a signed-in account's progress.
        GameRecordStore.shared.endBattleSession()
        entryMode = "guest"
        GameRecordStore.shared.refreshForCurrentAccount()
        navigateToGuest = true
    }
}

#Preview {
    NavigationStack {
        WelcomeView()
            .environmentObject(GameManager())
            .environmentObject(AuthManager())
            .environmentObject(AppRouteState())
    }
}

