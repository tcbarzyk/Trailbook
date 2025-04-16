//
//  AuthViewModel.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/14/25.
//

import FirebaseFirestore
import Foundation

class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var state: LoadingState = .idle
    var isLoading: Bool {
        if case .loading = state {
            return true
        }
        return false
    }

    public func handleSignUp(userSession: UserSession) {
        state = .loading
        userSession.signUp(email: email, password: password) { error in
            if let error = error {
                self.state = .error(error: error)
            } else {
                self.state = .success
                guard let currentUser = userSession.user else { return }

                // 1) Create a user doc in Firestore if it doesn't exist
                let db = Firestore.firestore()
                let userRef = db.collection("users").document(currentUser.uid)
                userRef.setData([
                    "userId": currentUser.uid,
                    "currentTripId": nil
                ]) { err in
                    if let err = err {
                        print("Error creating user doc: \(err)")
                    } else {
                        print("User doc created for \(currentUser.uid)")
                    }
                }
            }
        }
    }
    
    public func handleLogin(userSession: UserSession, tripSession: TripSession) {
        self.state = .loading
        userSession.logIn(email: email, password: password) { error in
            if let error = error {
                self.state = .error(error: error)
            } else {
                if let userId = userSession.user?.uid {
                    self.state = .success
                }
            }
        }
    }
}
