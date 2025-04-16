//
//  HomeViewModel.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/15/25.
//

import Foundation

class HomeViewModel: ObservableObject {
    @Published var loadCurrentTripState: LoadingState = .idle
    var isLoadingCurrentTrip: Bool {
        if case .loading = loadCurrentTripState {
            return true
        }
        return false
    }
    
    @Published var loadPastTripsState: LoadingState = .idle
    var isLoadingPastTrips: Bool {
        if case .loading = loadCurrentTripState {
            return true
        }
        return false
    }
    
    public func getPastTrips(tripSession: TripSession, userSession: UserSession) async {
        loadPastTripsState = .loading
        do {
            try await tripSession.fetchPastTrips(for: userSession.user?.uid ?? "")
            loadPastTripsState = .success
            print("Fetched trips")
        } catch {
            loadPastTripsState = .error(error: error)
            print("Error fetching trips: \(error)")
        }
    }
    
    public func getCurrentTrip(tripSession: TripSession, userSession: UserSession) async {
        loadCurrentTripState = .loading
        do {
            try await tripSession.fetchCurrentTrip(for: userSession.user?.uid ?? "")
            loadCurrentTripState = .success
            print("Fetched current trip")
        } catch {
            loadCurrentTripState = .error(error: error)
            print("Error fetching current trip: \(error)")
        }
    }
}
