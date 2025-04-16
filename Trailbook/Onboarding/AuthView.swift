//
//  AuthView.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/14/25.
//

import SwiftUI

struct AuthView: View {
    @StateObject private var vm = AuthViewModel()
    @ObservedObject public var userSession: UserSession
    @ObservedObject public var tripSession: TripSession
    @State public var isSignUpMode: Bool // switch between sign up and login

    var body: some View {
        VStack (spacing: 20) {
            Text(isSignUpMode ? "Create Account" : "Login")
                .font(.largeTitle)
                .bold()
                .padding(.top, 100)
            TextField("Email", text: $vm.email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $vm.password)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    handleAuthAction()
                }

            Button {
                handleAuthAction()
            } label: {
                Text(isSignUpMode ? "Sign Up" : "Log In")
                    .font(.title2)
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.isLoading)
            
            switch vm.state {
            case .idle:
                EmptyView()
            case .loading:
                ProgressView()
            case .success:
                EmptyView()
            case .error(let error):
                Text(error.localizedDescription)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private func handleAuthAction() {
        if isSignUpMode {
            vm.handleSignUp(userSession: userSession)
        } else {
            vm.handleLogin(userSession: userSession, tripSession: tripSession)
        }
    }
}

#Preview {
    NavigationStack {
        AuthView(userSession: UserSession(), tripSession: TripSession(), isSignUpMode: true)
    }
}
