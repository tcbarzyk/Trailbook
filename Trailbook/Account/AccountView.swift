//
//  AccountView.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/14/25.
//
import SwiftUI

struct AccountView: View {
    @ObservedObject public var userSession: UserSession
    @ObservedObject public var tripSession: TripSession
    
    var body: some View {
        VStack (spacing: 20) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 150, height: 150)
                .padding(.top, 150)
            Text(userSession.user?.email ?? "Unknown")
                .font(.title)
            Button("Log Out") {
                Task {
                    userSession.logOut()
                    tripSession.currentTrip = nil
                }
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        AccountView(userSession: UserSession(), tripSession: TripSession())
    }
}
