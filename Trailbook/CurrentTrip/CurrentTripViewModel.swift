//
//  CurrentTripViewModel.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/14/25.
//

import FirebaseFirestore
import Foundation

class CurrentTripViewModel: ObservableObject {
    @Published var creatingNewTrip: Bool = false
    @Published var showDayEntryView: Bool = false
    
    @Published var state: LoadingState = .idle
    var isLoading: Bool {
        if case .loading = self.state {
            return true
        }
        return false
    }
    
    // if trip not started -> end trip, delete the trip entirely
    public func endTripNotStarted(tripSession: TripSession) {
        self.state = .loading
        do {
            let db = Firestore.firestore()
            guard let trip = tripSession.currentTrip else {
                throw NSError(domain: "DayEntryError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get current trip"])
            }
            guard let tripId = trip.id else {
                throw NSError(domain: "DayEntryError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to get current trip ID"])
            }
            db.collection("trips").document(tripId).delete { error in
                if let error = error {
                    print("Error deleting document: \(error.localizedDescription)")
                    self.state = .error(error: error)
                } else {
                    print("Document successfully deleted")
                    tripSession.currentTrip = nil
                    tripSession.addedDayEntry = false
                    self.state = .success
                }
            }
        } catch {
            print("Error deleting trip: \(error.localizedDescription)")
            self.state = .error(error: error)
        }
    }
    
    // if trip in progress -> end trip, set isCompleted = true, and set end date to current date
    public func endTripInProgress(tripSession: TripSession, homeViewModel: HomeViewModel, userSession: UserSession) async {
        self.state = .loading
        do {
            let db = Firestore.firestore()
            guard let trip = tripSession.currentTrip else {
                throw NSError(domain: "DayEntryError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get current trip"])
            }
            guard let tripId = trip.id else {
                throw NSError(domain: "DayEntryError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to get current trip ID"])
            }
            db.collection("trips").document(tripId).updateData([
                "isCompleted": true, "endDate": Date()
            ]) { error in
                if let error = error {
                    print("Error updating document: \(error.localizedDescription)")
                    self.state = .error(error: error)
                } else {
                    print("Trip successfully marked as completed")
                    Task {
                        await homeViewModel.getPastTrips(tripSession: tripSession, userSession: userSession)
                        tripSession.currentTrip = nil
                        tripSession.addedDayEntry = false
                        self.state = .success
                    }
                }
            }
        } catch {
            print("Error ending trip: \(error.localizedDescription)")
            self.state = .error(error: error)
        }
    }
    
    // if trip already over -> end trip, set isCompleted = true
    public func endTripAlreadyOver(tripSession: TripSession, homeViewModel: HomeViewModel, userSession: UserSession) async {
        self.state = .loading
        do {
            let db = Firestore.firestore()
            guard let trip = tripSession.currentTrip else {
                throw NSError(domain: "DayEntryError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get current trip"])
            }
            guard let tripId = trip.id else {
                throw NSError(domain: "DayEntryError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to get current trip ID"])
            }
            db.collection("trips").document(tripId).updateData([
                "isCompleted": true
            ]) { error in
                if let error = error {
                    print("Error updating document: \(error.localizedDescription)")
                    self.state = .error(error: error)
                } else {
                    print("Trip successfully marked as completed")
                    Task {
                        await homeViewModel.getPastTrips(tripSession: tripSession, userSession: userSession)
                        tripSession.currentTrip = nil
                        tripSession.addedDayEntry = false
                        self.state = .success
                    }
                }
            }
        } catch {
            print("Error ending trip: \(error.localizedDescription)")
            self.state = .error(error: error)
        }
    }
}
