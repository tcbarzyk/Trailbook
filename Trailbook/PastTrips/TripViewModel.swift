//
//  TripViewModel.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/15/25.
//
import Foundation
import FirebaseFirestore

class TripViewModel: ObservableObject {
    @Published var dayEntries: [DayEntry] = []
    
    @Published var state: LoadingState = .idle
    var isLoading: Bool {
        if case .loading = state {
            return true
        }
        return false
    }
    
    func fetchDayEntries(forTrip tripId: String) async throws {
        let db = Firestore.firestore()
        let snapshot = try await db.collection("trips")
            .document(tripId)
            .collection("days")
            .getDocuments()
        
        let entries = snapshot.documents.compactMap { document in
            try? document.data(as: DayEntry.self)
        }
        
        dayEntries = entries
    }
}
