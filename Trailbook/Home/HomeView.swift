//
//  HomeView.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/14/25.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject public var userSession: UserSession
    @ObservedObject public var tripSession: TripSession
    @ObservedObject public var locationManager: LocationManager
    @ObservedObject public var healthKitManager: HealthKitManager
    @ObservedObject public var imageCacheManager: ImageCacheManager

    @StateObject private var vm = HomeViewModel()

    var body: some View {
        TabView {
            Tab("New Trip", systemImage: "plus.circle.fill") {
                CurrentTripView(userSession: userSession, tripSession: tripSession, locationManager: locationManager, healthKitManager: healthKitManager, homeViewModel: vm)
            }

            Tab("Past Trips", systemImage: "airplane.circle.fill") {
                PastTripsView(tripSession: tripSession, homeViewModel: vm, imageCacheManager: imageCacheManager)
            }

            Tab("Account", systemImage: "person.crop.circle.fill") {
                AccountView(userSession: userSession, tripSession: tripSession)
            }
        }
        .onAppear {
            Task {
                await vm.getCurrentTrip(tripSession: tripSession, userSession: userSession)
                await vm.getPastTrips(tripSession: tripSession, userSession: userSession)
            }
        }
    }
}
