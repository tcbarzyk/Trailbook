//
//  NewTripViewModel.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/14/25.
//

import FirebaseFirestore
import Foundation

class NewTripViewModel: ObservableObject {
    @Published var titleInput: String = ""
    @Published var startDateInput: Date = .init()
    @Published var hasEndDate: Bool = false
    @Published var endDateInput: Date = .init()

    @Published var state: LoadingState = .idle
    var isLoading: Bool {
        if case .loading = self.state {
            return true
        }
        return false
    }
    
    var isSuccessful: Bool {
        if case .success = self.state {
            return true
        }
        return false
    }

    public func saveTrip(trip: Trip,
                         userId: String,
                         tripSession: TripSession)
    {
        self.state = .loading
        let db = Firestore.firestore()
        
        do {
            // 1) Create the Firestore document
            let ref = try db.collection("trips").addDocument(from: trip)

            // 2) Get the docID
            let newTripId = ref.documentID

            // 3) Use your TripSession function to update currentTripId
            tripSession.setCurrentTrip(userId: userId, tripId: newTripId)

            // 4) Locally update the tripSession
            var updatedTrip = trip
            updatedTrip.id = newTripId // store doc ID in the local struct
            tripSession.currentTrip = updatedTrip
            
            self.state = .success

        } catch {
            print("Error adding trip: \(error)")
            self.state = .error(error: error)
        }
    }
}
