//
//  OnboardingContainerView.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/14/25.
//

import SwiftUI

struct OnboardingContainerView: View {
    @ObservedObject public var userSession: UserSession
    @ObservedObject public var tripSession: TripSession
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            HStack {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 50))
                Text("Trailbook")
                    .font(.system(size: 60))
                    .bold()
            }
            Spacer()
            NavigationLink(destination: AuthView(userSession: userSession, tripSession: tripSession, isSignUpMode: false)) {
                Text("Log In")
                    .font(.title3)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal, 50)
            NavigationLink(destination: AuthView(userSession: userSession, tripSession: tripSession, isSignUpMode: true)) {
                Text("Sign Up")
                    .font(.title3)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal, 50)
        }
        .padding(.bottom, 30)
    }
}

#Preview {
    NavigationStack {
        OnboardingContainerView(userSession: UserSession(), tripSession: TripSession())
    }
}
