//
//  UserSession.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/14/25.
//

import FirebaseAuth
import SwiftUI

class UserSession: ObservableObject {
    @Published var user: User? // from FirebaseAuth.User
    @Published var isLoggedIn: Bool = false

    private var authStateListener: AuthStateDidChangeListenerHandle?

    init() {
        // Listen for auth changes
        authStateListener = Auth.auth().addStateDidChangeListener { _, user in
            self.user = user
            self.isLoggedIn = (user != nil)
        }
    }

    // Cleanup
    deinit {
        if let handle = authStateListener {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func signUp(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { _, error in
            completion(error)
        }
    }

    func logIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            completion(error)
        }
    }

    func logOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Log out error: \(error)")
        }
    }
}
