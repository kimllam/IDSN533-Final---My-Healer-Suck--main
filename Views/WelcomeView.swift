
import SwiftUI

// MARK: - Welcome View
// Updated by Jingyi: Account selection after tapping Play.

struct WelcomeView: View {

    @AppStorage("entryMode")
    private var entryMode = ""

    private let background = Color(
        red: 252 / 255,
        green: 220 / 255,
        blue: 187 / 255
    )

    private let paper = Color(
        red: 255 / 255,
        green: 243 / 255,
        blue: 228 / 255
    )

    private let brown = Color(
        red: 89 / 255,
        green: 59 / 255,
        blue: 46 / 255
    )

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        Image("healer card")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 130)

                        Text("Ready to Play?")
                            .font(
                                .system(
                                    size: 30,
                                    weight: .black,
                                    design: .serif
                                )
                            )
                            .foregroundStyle(brown)

                        Text("Choose how you'd like to enter the game.")
                            .font(.system(size: 14))
                            .foregroundStyle(
                                brown.opacity(0.75)
                            )
                            .multilineTextAlignment(.center)

                        VStack(spacing: 14) {

                            NavigationLink {
                                GameBoardView()
                                    .onAppear {
                                        entryMode = "guest"
                                    }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "gamecontroller.fill")
                                    Text("Continue as Guest")
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .foregroundStyle(.white)
                                .background(
                                    brown,
                                    in: RoundedRectangle(
                                        cornerRadius: 13
                                    )
                                )
                            }

                            NavigationLink {
                                AuthView(mode: .signUp)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "person.badge.plus")
                                    Text("Create Account")
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .foregroundStyle(brown)
                                .background(
                                    background,
                                    in: RoundedRectangle(
                                        cornerRadius: 13
                                    )
                                )
                                .overlay {
                                    RoundedRectangle(
                                        cornerRadius: 13
                                    )
                                    .stroke(
                                        brown.opacity(0.4),
                                        lineWidth: 1
                                    )
                                }
                            }

                            NavigationLink {
                                AuthView(mode: .logIn)
                            } label: {
                                Text("Already have an account? Log In")
                                    .font(.system(
                                        size: 14,
                                        weight: .semibold
                                    ))
                                    .foregroundStyle(brown)
                                    .underline()
                                    .padding(.top, 10)
                            }
                        }
                        .font(.system(
                            size: 16,
                            weight: .semibold
                        ))
                        .buttonStyle(.plain)
                        .padding(.top, 10)
                    }
                    .padding(24)
                    .frame(maxWidth: 365)
                    .background(
                        paper,
                        in: RoundedRectangle(
                            cornerRadius: 22
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(
                                brown.opacity(0.7),
                                lineWidth: 1.5
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height,
                        alignment: .center
                    )
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .tint(brown)
    }
}

#Preview {
    NavigationStack {
        WelcomeView()
            .environmentObject(GameManager())
    }
}

