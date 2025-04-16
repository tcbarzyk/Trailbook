//
//  TripSession.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/14/25.
//
import FirebaseFirestore
import SwiftUI

class TripSession: ObservableObject {
    @Published var currentTrip: Trip?
    @Published var pastTrips: [Trip] = []
    
    @Published var addedDayEntry: Bool = false
    
    func setCurrentTrip(userId: String, tripId: String?) {
        print("Setting user \(userId) to trip \(tripId ?? "nil")")
        let db = Firestore.firestore()
        db.collection("users").document(userId).setData(["currentTripId": tripId ?? FieldValue.delete()],
                                                        merge: true)
    }
    
    func fetchPastTrips(for userID: String) async throws {
        let db = Firestore.firestore()
        let querySnapshot = try await db.collection("trips")
            .whereField("userId", isEqualTo: userID)
            .whereField("isCompleted", isEqualTo: true)
            .getDocuments()
        
        let trips = querySnapshot.documents.compactMap { try? $0.data(as: Trip.self) }
        pastTrips = trips
    }
    
    func fetchCurrentTrip(for userID: String) async throws {
        let db = Firestore.firestore()
        let querySnapshot = try await db.collection("trips")
            .whereField("userId", isEqualTo: userID)
            .whereField("isCompleted", isEqualTo: false)
            .getDocuments()
        
        let trips = querySnapshot.documents.compactMap { try? $0.data(as: Trip.self) }
        
        if (trips.count == 1) {
            currentTrip = trips[0]
            // 1) Ensure we have a current trip & ID
            guard let trip = self.currentTrip else {
                throw NSError(domain: "DayEntryError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get current trip"])
            }
            guard let tripId = trip.id else {
                throw NSError(domain: "DayEntryError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to get current trip ID"])
            }
            self.checkIfDayEntryExistsForToday(in: tripId)
        }
        else if (trips.count > 1) {
            currentTrip = trips[0]
            // 1) Ensure we have a current trip & ID
            guard let trip = self.currentTrip else {
                throw NSError(domain: "DayEntryError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get current trip"])
            }
            guard let tripId = trip.id else {
                throw NSError(domain: "DayEntryError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to get current trip ID"])
            }
            self.checkIfDayEntryExistsForToday(in: tripId)
            
            print("There are more than one current trips for user!")
        }
        else if (trips.count == 0) {
            currentTrip = nil
            print("no current trip found!")
        }
    }
    
    private func checkIfDayEntryExistsForToday(in tripId: String) {
        let db = Firestore.firestore()
        // We'll compare using startOfDay... < next day
        let startOfToday = Calendar.current.startOfDay(for: Date())
        guard let endOfToday = Calendar.current.date(byAdding: .day, value: 1, to: startOfToday) else { return }
        
        db.collection("trips")
            .document(tripId)
            .collection("days")
            .whereField("date", isGreaterThanOrEqualTo: startOfToday)
            .whereField("date", isLessThan: endOfToday)
            .limit(to: 1) // if we find any, that's enough
            .getDocuments { querySnapshot, error in
                guard error == nil else {
                    print("Error checking day entries: \(error!.localizedDescription)")
                    return
                }
                
                let docs = querySnapshot?.documents ?? []
                if !docs.isEmpty {
                    DispatchQueue.main.async {
                        self.addedDayEntry = true
                        print("Already have a day entry for today → addedDayEntry = true")
                    }
                } else {
                    DispatchQueue.main.async {
                        self.addedDayEntry = false
                        print("No day entry yet for today → addedDayEntry = false")
                    }
                }
            }
    }
}

extension TripSession {
    static var preview: TripSession {
        let session = TripSession()
        session.currentTrip = Trip.sample
        return session
    }
}
