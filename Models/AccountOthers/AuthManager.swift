
//
//  AuthManager.swift
//  IDSN533 MyHealerSuck
//
//  Created by Jingyi on 11/15/26.
//  Updated by Jingyi: Email verification support.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

// MARK: - Firebase Authentication Manager
// Added by Jingyi: Manage user authentication
// and verified email status.

@MainActor
final class AuthManager: ObservableObject {

    // MARK: - Authentication State

    @Published private(set) var isLoggedIn = false
    @Published private(set) var isEmailVerified = false
    @Published private(set) var userID: String?
    @Published private(set) var email: String?
    @Published private(set) var hasCheckedAuthState = false

    private var authListener: AuthStateDidChangeListenerHandle?

    // MARK: - Initialization

    init() {
        authListener = Auth.auth().addStateDidChangeListener {
            [weak self] _, user in

            let uid = user?.uid
            let userEmail = user?.email
            let verified = user?.isEmailVerified ?? false

            Task { @MainActor [weak self] in
                self?.userID = uid
                self?.email = userEmail
                self?.isLoggedIn = uid != nil
                self?.isEmailVerified = verified
                self?.hasCheckedAuthState = true
            }
        }
    }

    // MARK: - Register
    // Updated by Jingyi: Send an email verification
    // after creating a Firebase account.

    func signUp(
        email: String,
        password: String
    ) async throws {

        let cleanedEmail = email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let result = try await Auth.auth().createUser(
            withEmail: cleanedEmail,
            password: password
        )

        // A newly created email/password account
        // must verify its email before gameplay.

        try await result.user.sendEmailVerification()

        isEmailVerified = false
    }

    // MARK: - Log In

    func logIn(
        email: String,
        password: String
    ) async throws {

        let cleanedEmail = email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let result = try await Auth.auth().signIn(
            withEmail: cleanedEmail,
            password: password
        )

        // Refresh verification status from Firebase.

        try await result.user.reload()

        isEmailVerified =
            Auth.auth().currentUser?.isEmailVerified ?? false
    }

    // MARK: - Resend Verification Email
    // Added by Jingyi: Allow users to request
    // another verification email.

    func resendVerificationEmail() async throws {

        guard let user = Auth.auth().currentUser else {
            throw AuthError.noCurrentUser
        }

        try await user.reload()

        guard !user.isEmailVerified else {
            isEmailVerified = true
            return
        }

        try await user.sendEmailVerification()
    }

    // MARK: - Check Verification Status
    // Added by Jingyi: Reload the Firebase user
    // before checking the verified email flag.

    @discardableResult
    func checkEmailVerification() async throws -> Bool {

        guard let user = Auth.auth().currentUser else {
            throw AuthError.noCurrentUser
        }

        try await user.reload()

        let verified =
            Auth.auth().currentUser?.isEmailVerified ?? false

        isEmailVerified = verified

        return verified
    }

    // MARK: - Log Out

    func logOut() throws {
        try Auth.auth().signOut()

        isLoggedIn = false
        isEmailVerified = false
        userID = nil
        email = nil
    }

    // MARK: - Reset Password

    func resetPassword(
        email: String
    ) async throws {

        let cleanedEmail = email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        try await Auth.auth().sendPasswordReset(
            withEmail: cleanedEmail
        )
    }

    // MARK: - Delete Account

    func deleteAccount(password: String) async throws {
        guard let user = Auth.auth().currentUser,
              let currentEmail = user.email,
              !currentEmail.isEmpty else {
            throw AuthError.noCurrentUser
        }

        guard !password.isEmpty else {
            throw AuthError.passwordRequired
        }

        let uid = user.uid
        let credential = EmailAuthProvider.credential(
            withEmail: currentEmail,
            password: password
        )

        // Confirm the account owner before removing any cloud data.
        try await user.reauthenticate(with: credential)

        let userDocument = Firestore.firestore()
            .collection("users")
            .document(uid)
        let battlesCollection = userDocument.collection("battles")

        // Firestore does not recursively delete subcollections.
        // Use small batches and fetch from the server to verify completion.
        while true {
            let snapshot = try await battlesCollection
                .limit(to: 100)
                .getDocuments(source: .server)

            if snapshot.documents.isEmpty { break }

            let batch = Firestore.firestore().batch()
            for document in snapshot.documents {
                batch.deleteDocument(document.reference)
            }
            try await batch.commit()
        }

        try await userDocument.delete()

        // Only delete Authentication after the known Firestore data is gone.
        // A failed operation keeps the account available for a retry.
        try await user.delete()

        isLoggedIn = false
        isEmailVerified = false
        userID = nil
        email = nil
    }

    // MARK: - Authentication Errors

    enum AuthError: LocalizedError {
        case noCurrentUser
        case passwordRequired

        var errorDescription: String? {
            switch self {
            case .noCurrentUser:
                return "No signed-in account was found."
            case .passwordRequired:
                return "Enter your password to confirm account deletion."
            }
        }
    }
}


