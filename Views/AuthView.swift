//
//  AuthView.swift
//  IDSN533 MyHealerSuck
//

import SwiftUI

enum AuthMode {
    case logIn
    case signUp
}

struct AuthView: View {
    var onAuthenticated: () -> Void = {}
    var onPlayAsGuest: () -> Void = {}

    init(
        mode: AuthMode = .logIn,
        onAuthenticated: @escaping () -> Void = {},
        onPlayAsGuest: @escaping () -> Void = {},
        onContinueAsGuest: (() -> Void)? = nil
    ) {
        self.onAuthenticated = onAuthenticated
        self.onPlayAsGuest = onContinueAsGuest ?? onPlayAsGuest
        _isSignUpMode = State(initialValue: mode == .signUp)
    }

    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var game: GameManager
    @EnvironmentObject private var appRoute: AppRouteState
    @AppStorage("entryMode") private var entryMode = ""

    @State private var isSignUpMode = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var statusMessage: String?
    @State private var isErrorMessage = false

    private let cardCornerRadius: CGFloat = 24

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let isLandscape = size.width > size.height
            let compact = isLandscape && size.height < 460

            // Size the parchment card so it fits cleanly in landscape without scrolling
            let maxCardWidth: CGFloat = isLandscape
                ? min(470, max(370, size.width * 0.50))
                : min(430, max(310, size.width - 36))

            let maxCardHeight: CGFloat = max(330, size.height - (compact ? 16 : 48))

            ZStack {
                // Centered auth parchment card over full-bleed gameboard background
                authCard(compact: compact, isLandscape: isLandscape)
                    .frame(width: maxCardWidth)
                    .frame(maxHeight: maxCardHeight)
            }
            .frame(width: size.width, height: size.height)
            .background {
                ZStack {
                    AppTheme.backgroundTan

                    Image("gameboardbg")
                        .resizable()
                        .scaledToFill()
                        .saturation(0.75)

                    AppTheme.backgroundTan.opacity(0.28)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
        .environment(\.colorScheme, .light)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Auth Card

    private func authCard(compact: Bool, isLandscape: Bool) -> some View {
        let vSpacing: CGFloat = compact ? 6 : 11
        let fieldHeight: CGFloat = compact ? 33 : 40
        let buttonHeight: CGFloat = compact ? 35 : 42
        let cardShape = RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)

        return VStack(spacing: vSpacing) {
            // Header
            VStack(spacing: compact ? 1 : 3) {
                HStack(spacing: 6) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: compact ? 12 : 15))
                        .foregroundStyle(AppTheme.darkBrown.opacity(0.75))
                        .rotationEffect(.degrees(-35))

                    Text("Player Login")
                        .font(.system(size: compact ? 19 : 25, weight: .bold, design: .serif))
                        .foregroundStyle(AppTheme.darkBrown)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Image(systemName: "leaf.fill")
                        .font(.system(size: compact ? 12 : 15))
                        .foregroundStyle(AppTheme.darkBrown.opacity(0.75))
                        .scaleEffect(x: -1, y: 1)
                        .rotationEffect(.degrees(35))
                }

                Text("Save your progress & earn achievements.")
                    .font(.system(size: compact ? 11 : 13, weight: .medium, design: .serif))
                    .foregroundStyle(AppTheme.darkBrown.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            // Email Field
            VStack(alignment: .leading, spacing: compact ? 2 : 4) {
                Text("Email")
                    .font(.system(size: compact ? 11 : 13, weight: .bold))
                    .foregroundStyle(AppTheme.darkBrown)

                HStack(spacing: 8) {
                    Image(systemName: "envelope")
                        .font(.system(size: compact ? 13 : 15, weight: .medium))
                        .foregroundStyle(AppTheme.darkBrown.opacity(0.72))
                        .frame(width: 18)

                    TextField("Enter your email", text: $email)
                        .font(.system(size: compact ? 13 : 15))
                        .foregroundStyle(AppTheme.darkBrown)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 12)
                .frame(height: fieldHeight)
                .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppTheme.darkBrown.opacity(0.65), lineWidth: 1.2)
                }
            }

            // Password Field(s)
            if isSignUpMode && isLandscape {
                // Side-by-side in landscape sign-up so height never forces scrolling
                HStack(spacing: 8) {
                    passwordFieldBlock(
                        title: "Password",
                        placeholder: "Create password",
                        text: $password,
                        compact: compact,
                        height: fieldHeight
                    )

                    passwordFieldBlock(
                        title: "Confirm",
                        placeholder: "Re-enter",
                        text: $confirmPassword,
                        compact: compact,
                        height: fieldHeight
                    )
                }
            } else {
                VStack(alignment: .leading, spacing: compact ? 2 : 4) {
                    passwordFieldBlock(
                        title: "Password",
                        placeholder: "Enter your password",
                        text: $password,
                        compact: compact,
                        height: fieldHeight
                    )

                    if isSignUpMode {
                        passwordFieldBlock(
                            title: "Confirm Password",
                            placeholder: "Re-enter your password",
                            text: $confirmPassword,
                            compact: compact,
                            height: fieldHeight
                        )
                        .padding(.top, 2)
                    } else {
                        HStack {
                            Spacer()

                            Button(action: handleForgotPassword) {
                                Text("Forgot password?")
                                    .font(.system(size: compact ? 10 : 12, weight: .semibold))
                                    .underline()
                                    .foregroundStyle(AppTheme.darkBrown)
                            }
                            .buttonStyle(.plain)
                            .disabled(isLoading)
                        }
                    }
                }
            }

            // Inline feedback banner (if any)
            if let statusMessage {
                Text(statusMessage)
                    .font(.system(size: compact ? 10 : 12, weight: .medium))
                    .foregroundStyle(isErrorMessage ? Color.red : AppTheme.darkBrown)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            // Primary Submit Button ("Log in" / "Create account")
            Button(action: handlePrimarySubmit) {
                HStack(spacing: 6) {
                    if isLoading {
                        ProgressView()
                            .tint(AppTheme.paper)
                            .scaleEffect(0.8)
                    }
                    Text(isSignUpMode ? "Create account" : "Log in")
                        .font(.system(size: compact ? 15 : 17, weight: .bold, design: .serif))
                        .foregroundStyle(AppTheme.paper)
                }
                .frame(maxWidth: .infinity)
                .frame(height: buttonHeight)
                .background(AppTheme.darkBrown, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(AppTheme.darkBrown, lineWidth: 1.5)
                }
                .shadow(color: .black.opacity(0.16), radius: 3, y: 2)
            }
            .buttonStyle(.plain)
            .disabled(isLoading)

            // Mode Switch Link
            HStack(spacing: 4) {
                Text(isSignUpMode ? "Already have an account?" : "New here?")
                    .font(.system(size: compact ? 11 : 13, weight: .medium))
                    .foregroundStyle(AppTheme.darkBrown)

                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        isSignUpMode.toggle()
                        statusMessage = nil
                    }
                } label: {
                    Text(isSignUpMode ? "Log in" : "Create account")
                        .font(.system(size: compact ? 11 : 13, weight: .bold))
                        .underline()
                        .foregroundStyle(AppTheme.darkBrown)
                }
                .buttonStyle(.plain)
            }

            // "or" Divider
            HStack(spacing: 10) {
                Rectangle()
                    .fill(AppTheme.darkBrown.opacity(0.35))
                    .frame(height: 1)

                Text("or")
                    .font(.system(size: compact ? 11 : 12, weight: .semibold, design: .serif))
                    .foregroundStyle(AppTheme.darkBrown.opacity(0.75))

                Rectangle()
                    .fill(AppTheme.darkBrown.opacity(0.35))
                    .frame(height: 1)
            }
            .padding(.horizontal, 12)

            // Secondary Guest Button
            VStack(spacing: compact ? 2 : 4) {
                Button(action: handlePlayAsGuest) {
                    Text("Play as guest")
                        .font(.system(size: compact ? 14 : 16, weight: .bold, design: .serif))
                        .foregroundStyle(AppTheme.darkBrown)
                        .frame(maxWidth: .infinity)
                        .frame(height: compact ? 33 : 38)
                        .background(AppTheme.lightTan, in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(AppTheme.darkBrown, lineWidth: 1.4)
                        }
                }
                .buttonStyle(.plain)

               
            }
        }
        .padding(.horizontal, compact ? 36 : 44)
        .padding(.vertical, compact ? 30 : 38)
        .background {
            ZStack {
                Image("authbackground")
                    .resizable()

                
            }
            .clipShape(cardShape)
            .shadow(color: .black.opacity(0.28), radius: 14, y: 6)
        }
    }

    // MARK: - Password Field Helper

    private func passwordFieldBlock(
        title: String,
        placeholder: String,
        text: Binding<String>,
        compact: Bool,
        height: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: compact ? 2 : 4) {
            Text(title)
                .font(.system(size: compact ? 11 : 13, weight: .bold))
                .foregroundStyle(AppTheme.darkBrown)

            HStack(spacing: 8) {
                Image(systemName: "lock")
                    .font(.system(size: compact ? 13 : 15, weight: .medium))
                    .foregroundStyle(AppTheme.darkBrown.opacity(0.72))
                    .frame(width: 18)

                SecureField(placeholder, text: text)
                    .font(.system(size: compact ? 13 : 15))
                    .foregroundStyle(AppTheme.darkBrown)
            }
            .padding(.horizontal, 12)
            .frame(height: height)
            .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppTheme.darkBrown.opacity(0.65), lineWidth: 1.2)
            }
        }
    }

    // MARK: - Actions

    private func handlePrimarySubmit() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            isErrorMessage = true
            statusMessage = "Please enter both your email and password."
            return
        }

        if isSignUpMode && password != confirmPassword {
            isErrorMessage = true
            statusMessage = "Passwords do not match."
            return
        }

        isLoading = true
        statusMessage = nil

        Task { @MainActor in
            defer { isLoading = false }
            do {
                if isSignUpMode {
                    // Create the Firebase user and send the verification email.
                    try await auth.signUp(email: trimmedEmail, password: password)
                    isErrorMessage = false
                    statusMessage = "Account created. Check your email, verify your address, then log in."
                    isSignUpMode = false
                    confirmPassword = ""
                    password = ""
                    return
                }

                // Do not activate account mode until Firebase confirms the login.
                try await auth.logIn(email: trimmedEmail, password: password)
                let verified = try await auth.checkEmailVerification()
                guard verified else {
                    isErrorMessage = true
                    statusMessage = "Please verify your email before playing with an account."
                    return
                }

                entryMode = "account"
                GameRecordStore.shared.refreshForCurrentAccount()
                onAuthenticated()
            } catch {
                isErrorMessage = true
                statusMessage = error.localizedDescription
            }
        }
    }

    private func handleForgotPassword() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            isErrorMessage = true
            statusMessage = "Enter your email above to receive a reset link."
            return
        }

        Task { @MainActor in
            do {
                try await auth.resetPassword(email: trimmedEmail)
                isErrorMessage = false
                statusMessage = "Password reset email sent."
            } catch {
                isErrorMessage = true
                statusMessage = error.localizedDescription
            }
        }
    }

    private func handlePlayAsGuest() {
        // Guest play never inherits a registered Firebase session.
        do {
            if auth.isLoggedIn {
                try auth.logOut()
            }
            entryMode = "guest"
            GameRecordStore.shared.refreshForCurrentAccount()
            onPlayAsGuest()
        } catch {
            isErrorMessage = true
            statusMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview

#Preview {
    AuthView()
        .environmentObject(AuthManager())
        .environmentObject(GameManager())
        .environmentObject(AppRouteState())
}

