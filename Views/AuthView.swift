
//
//  AuthView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Jingyi on 11/15/26.
//  Updated by Jingyi: Firebase Authentication and email verification.
//  Updated by Jingyi: Consistent landscape navigation.
//

import SwiftUI

struct AuthView: View {
    var onContinueAsGuest: () -> Void = {}
    
    enum Mode {
        case signUp
        case logIn}

    @EnvironmentObject private var auth: AuthManager
    @AppStorage("entryMode") private var entryMode = ""

    @State private var mode: Mode

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    @State private var showPassword = false
    @State private var isSubmitting = false

    @State private var showVerification = false
    @State private var navigateToGame = false

    @State private var showAlert = false
    @State private var alertTitle = "Account"
    @State private var alertMessage = ""

    // MARK: - Initialization

    init(
        mode: Mode = .logIn,
        onContinueAsGuest: @escaping () -> Void = {}
    ) {
        _mode = State(initialValue: mode)
        self.onContinueAsGuest = onContinueAsGuest
    }

    private var isSignUp: Bool {
        mode == .signUp
    }

    // MARK: - Main View

        var body: some View {
            GeometryReader { geometry in
                ZStack {
                    AppTheme.backgroundTan
                        .ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 22) {
                            if showVerification {
                                verificationHeader
                                verificationPanel
                            } else {
                                authenticationHeader
                                authenticationPanel

    // MARK: - Guest Option
                                Button(action: {
                                    onContinueAsGuest()
                                }) {
                                    Text("Play as Guest")
                                        .font(.headline)
                                        .foregroundColor(AppTheme.darkBrown)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(AppTheme.darkBrown.opacity(0.12))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(AppTheme.darkBrown.opacity(0.35), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .frame(maxWidth: 380)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 24)
                        .frame(
                            maxWidth: .infinity,
                            minHeight: geometry.size.height,
                            alignment: .center
                        )
                    }
                    .scrollIndicators(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .tint(AppTheme.darkBrown)
            .alert(
                alertTitle,
                isPresented: $showAlert
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }

    // MARK: - Authentication Header

    private var authenticationHeader: some View {
        VStack(spacing: 12) {
            Image(
                systemName: isSignUp
                    ? "person.crop.circle.badge.plus"
                    : "person.crop.circle"
            )
            .font(.system(size: 48))
            .foregroundStyle(AppTheme.darkBrown)

            Text(
                isSignUp
                    ? "Create Account"
                    : "Welcome Back"
            )
            .font(
                .system(
                    size: 29,
                    weight: .black,
                    design: .serif
                )
            )
            .foregroundStyle(AppTheme.darkBrown)

            Text(
                isSignUp
                    ? "Join the chaos."
                    : "Your idiots are waiting."
            )
            .font(
                .system(
                    size: 15,
                    design: .serif
                )
            )
            .italic()
            .foregroundStyle(
                AppTheme.darkBrown.opacity(0.7)
            )
        }
        .multilineTextAlignment(.center)
    }

    // MARK: - Authentication Panel

    private var authenticationPanel: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            emailField
            passwordField

            if isSignUp {
                confirmPasswordField
            }

            // MARK: - Submit Button

            Button {
                Task {
                    await submit()
                }
            } label: {
                HStack(spacing: 10) {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    }

                    Text(
                        isSignUp
                            ? "Create Account"
                            : "Log In"
                    )
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    AppTheme.darkBrown,
                    in: RoundedRectangle(
                        cornerRadius: 13
                    )
                )
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting)
            .opacity(isSubmitting ? 0.65 : 1)
            .padding(.top, 8)

  // MARK: - Password Reset

            if !isSignUp {
                Button {
                    Task {
                        await resetPassword()
                    }
                } label: {
                    Text("Forgot Password?")
                        .font(
                            .system(
                                size: 14,
                                weight: .semibold
                            )
                        )
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .disabled(isSubmitting)
            }

            // MARK: - Switch Mode

            Button {
                switchMode()
            } label: {
                Text(
                    isSignUp
                        ? "Already have an account? Log In"
                        : "New player? Create Account"
                )
                .font(
                    .system(
                        size: 14,
                        weight: .semibold
                    )
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting)
        }
        .foregroundStyle(AppTheme.darkBrown)
        .padding(22)
        .background(
            AppTheme.paper,
            in: RoundedRectangle(
                cornerRadius: 20
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 20
            )
            .stroke(
                AppTheme.darkBrown.opacity(0.6),
                lineWidth: 1.5
            )
        }
    }

    // MARK: - Email Field

    private var emailField: some View {
        VStack(
            alignment: .leading,
            spacing: 7
        ) {
            Text("Email")
                .font(.subheadline.bold())

            TextField(
                "you@example.com",
                text: $email
            )
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(14)
            .background(
                Color.white.opacity(0.85),
                in: RoundedRectangle(
                    cornerRadius: 12
                )
            )
        }
    }

    // MARK: - Password Field

    private var passwordField: some View {
        VStack(
            alignment: .leading,
            spacing: 7
        ) {
            Text("Password")
                .font(.subheadline.bold())

            HStack(spacing: 10) {
                Group {
                    if showPassword {
                        TextField(
                            "Password",
                            text: $password
                        )
                    } else {
                        SecureField(
                            "Password",
                            text: $password
                        )
                    }
                }
                .textContentType(
                    isSignUp
                        ? .newPassword
                        : .password
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                Button {
                    showPassword.toggle()
                } label: {
                    Image(
                        systemName: showPassword
                            ? "eye.slash"
                            : "eye"
                    )
                    .foregroundStyle(AppTheme.darkBrown)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(
                Color.white.opacity(0.85),
                in: RoundedRectangle(
                    cornerRadius: 12
                )
            )
        }
    }

    // MARK: - Confirm Password Field

    private var confirmPasswordField: some View {
        VStack(
            alignment: .leading,
            spacing: 7
        ) {
            Text("Confirm Password")
                .font(.subheadline.bold())

            SecureField(
                "Confirm password",
                text: $confirmPassword
            )
            .textContentType(.newPassword)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(14)
            .background(
                Color.white.opacity(0.85),
                in: RoundedRectangle(
                    cornerRadius: 12
                )
            )
        }
    }

    // MARK: - Verification Header

    private var verificationHeader: some View {
        VStack(spacing: 14) {
            Image(
                systemName: "envelope.badge.shield.half.filled"
            )
            .font(.system(size: 54))
            .foregroundStyle(AppTheme.darkBrown)
            .symbolRenderingMode(.hierarchical)

            Text("Verify Your Email")
                .font(
                    .system(
                        size: 30,
                        weight: .black,
                        design: .serif
                    )
                )
                .foregroundStyle(AppTheme.darkBrown)

            Text("One more step before the chaos begins.")
                .font(
                    .system(
                        size: 15,
                        design: .serif
                    )
                )
                .italic()
                .foregroundStyle(
                    AppTheme.darkBrown.opacity(0.75)
                )
        }
        .multilineTextAlignment(.center)
    }

    // MARK: - Verification Panel
    // Added by Jingyi: Verification status,
    // resend email, and account switching.

    private var verificationPanel: some View {
        VStack(spacing: 20) {
            Image(systemName: "mail")
                .font(.system(size: 32))
                .foregroundStyle(AppTheme.darkBrown)

            Text("Check Your Inbox")
                .font(
                    .system(
                        size: 22,
                        weight: .bold,
                        design: .serif
                    )
                )
                .foregroundStyle(AppTheme.darkBrown)

            Text(
                "We've sent a verification link to:"
            )
            .font(.system(size: 15))
            .foregroundStyle(
                AppTheme.darkBrown.opacity(0.8)
            )
            .multilineTextAlignment(.center)

            Text(auth.email ?? email)
                .font(
                    .system(
                        size: 15,
                        weight: .semibold
                    )
                )
                .foregroundStyle(AppTheme.darkBrown)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)

            Divider()
                .overlay(
                    AppTheme.outline.opacity(0.4)
                )

            Text(
                "Open the email and tap the verification link. Then return to the game."
            )
            .font(.system(size: 15))
            .foregroundStyle(
                AppTheme.darkBrown.opacity(0.85)
            )
            .multilineTextAlignment(.center)
            .fixedSize(
                horizontal: false,
                vertical: true
            )

            // MARK: - Check Verification

            Button {
                Task {
                    await checkVerification()
                }
            } label: {
                HStack(spacing: 10) {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(
                            systemName: "checkmark.seal.fill"
                        )
                    }

                    Text("I've Verified My Email")
                }
                .font(
                    .system(
                        size: 16,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    AppTheme.darkBrown,
                    in: RoundedRectangle(
                        cornerRadius: 13
                    )
                )
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting)

            // MARK: - Resend Verification

            Button {
                Task {
                    await resendVerification()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(
                        systemName: "arrow.clockwise"
                    )

                    Text("Resend Verification Email")
                }
                .font(
                    .system(
                        size: 14,
                        weight: .semibold
                    )
                )
                .foregroundStyle(AppTheme.darkBrown)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    AppTheme.backgroundTan,
                    in: RoundedRectangle(
                        cornerRadius: 12
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: 12
                    )
                    .stroke(
                        AppTheme.outline.opacity(0.7),
                        lineWidth: 1
                    )
                }
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting)

            // MARK: - Switch Account

            Button {
                useAnotherAccount()
            } label: {
                Text("Use Another Account")
                    .font(
                        .system(
                            size: 14,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        AppTheme.darkBrown.opacity(0.85)
                    )
                    .underline()
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting)
        }
        .padding(24)
        .background(
            AppTheme.paper,
            in: RoundedRectangle(
                cornerRadius: 22
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 22
            )
            .stroke(
                AppTheme.outline.opacity(0.85),
                lineWidth: 1.2
            )
        }
    }

    // MARK: - Switch Authentication Mode

    private func switchMode() {
        mode = isSignUp ? .logIn : .signUp

        password = ""
        confirmPassword = ""
        showPassword = false
    }

    // MARK: - Firebase Registration and Login
    // Updated by Jingyi: Require verified email
    // before allowing registered gameplay.

    @MainActor
    private func submit() async {
        guard !isSubmitting else {
            return
        }

        let cleanedEmail = email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let parts = cleanedEmail.split(
            separator: "@",
            omittingEmptySubsequences: false
        )

        guard parts.count == 2,
              !parts[0].isEmpty,
              !parts[1].isEmpty,
              parts[1].contains(".")
        else {
            showMessage(
                title: "Invalid Email",
                message: "Please enter a valid email address."
            )
            return
        }

        guard !password.isEmpty else {
            showMessage(
                title: "Password Required",
                message: "Please enter a password."
            )
            return
        }

        if isSignUp {
            guard password.count >= 6 else {
                showMessage(
                    title: "Invalid Password",
                    message: "Password must be at least 6 characters."
                )
                return
            }

            guard password == confirmPassword else {
                showMessage(
                    title: "Passwords Do Not Match",
                    message: "Please make sure both passwords match."
                )
                return
            }
        }

        isSubmitting = true

        defer {
            isSubmitting = false
        }

        do {
            if isSignUp {
                // Firebase creates the account
                // and sends the verification email.

                try await auth.signUp(
                    email: cleanedEmail,
                    password: password
                )

                // Do not navigate to gameplay
                // before email verification.

                showVerification = true

            } else {
                // Authenticate the existing account.

                try await auth.logIn(
                    email: cleanedEmail,
                    password: password
                )

                // Check the latest verified status.

                let verified =
                    try await auth.checkEmailVerification()

                if verified {
                    entryMode = "account"
                    navigateToGame = true
                } else {
                    showVerification = true
                }
            }

        } catch {
            showMessage(
                title: "Authentication Failed",
                message: error.localizedDescription
            )
        }
    }

    // MARK: - Check Email Verification
    // Added by Jingyi: Refresh Firebase user state.

    @MainActor
    private func checkVerification() async {
        guard !isSubmitting else {
            return
        }

        isSubmitting = true

        defer {
            isSubmitting = false
        }

        do {
            let verified =
                try await auth.checkEmailVerification()

            if verified {
                // Enter the game only after
                // Firebase confirms verification.

                entryMode = "account"
                navigateToGame = true

            } else {
                showMessage(
                    title: "Email Not Verified",
                    message: "Your email has not been verified yet. Please open the verification link in your inbox and try again."
                )
            }

        } catch {
            showMessage(
                title: "Verification Error",
                message: error.localizedDescription
            )
        }
    }

    // MARK: - Resend Verification Email

    @MainActor
    private func resendVerification() async {
        guard !isSubmitting else {
            return
        }

        isSubmitting = true

        defer {
            isSubmitting = false
        }

        do {
            try await auth.resendVerificationEmail()

            showMessage(
                title: "Verification Email",
                message: "If your email is not yet verified, another verification message has been requested. Please check your inbox and spam folder."
            )

        } catch {
            showMessage(
                title: "Unable to Send Email",
                message: error.localizedDescription
            )
        }
    }

    // MARK: - Use Another Account
    // Added by Jingyi: Clear the unverified session
    // before returning to the login form.

    private func useAnotherAccount() {
        do {
            try auth.logOut()

            showVerification = false
            mode = .logIn

            email = ""
            password = ""
            confirmPassword = ""
            showPassword = false

        } catch {
            showMessage(
                title: "Sign Out Failed",
                message: error.localizedDescription
            )
        }
    }

    // MARK: - Password Reset

    @MainActor
    private func resetPassword() async {
        guard !isSubmitting else {
            return
        }

        let cleanedEmail = email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanedEmail.isEmpty else {
            showMessage(
                title: "Email Required",
                message: "Enter your email address first."
            )
            return
        }

        isSubmitting = true

        defer {
            isSubmitting = false
        }

        do {
            try await auth.resetPassword(
                email: cleanedEmail
            )

            showMessage(
                title: "Password Reset",
                message: "If this email is eligible, password reset instructions will be sent."
            )

        } catch {
            showMessage(
                title: "Password Reset Failed",
                message: error.localizedDescription
            )
        }
    }

    // MARK: - Alert Helper

    private func showMessage(
        title: String,
        message: String
    ) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AuthView(mode: .signUp)
    }
    .environmentObject(GameManager())
    .environmentObject(AuthManager())
}


