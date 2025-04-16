//
//  ContentView.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/14/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var userSession = UserSession()
    @StateObject private var tripSession = TripSession()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var imageCacheManager = ImageCacheManager()
    @State private var isLoadingHealthAuth: Bool = false

    var body: some View {
        Group {
            if (userSession.isLoggedIn && locationManager.hasLocationAccess && !isLoadingHealthAuth) {
                NavigationStack {
                    HomeView(userSession: userSession, tripSession: tripSession, locationManager: locationManager, healthKitManager: healthKitManager, imageCacheManager: imageCacheManager)
                }
            }
            else if (userSession.isLoggedIn && !locationManager.hasLocationAccess) {
                NavigationStack {
                    RequestLocationAccessView(locationManager: locationManager)
                }
            }
            else if (!userSession.isLoggedIn) {
                NavigationStack {
                    OnboardingContainerView(userSession: userSession, tripSession: tripSession)
                }
            }
            else if (isLoadingHealthAuth) {
                ProgressView()
            }
        }
        .onAppear {
            Task {
                isLoadingHealthAuth = true
                await healthKitManager.requestHealthAuthorization()
                isLoadingHealthAuth = false
            }
        }
    }
}

#Preview {
    ContentView()
}
