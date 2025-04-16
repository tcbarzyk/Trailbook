//
//  PastTripsViewModel.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/15/25.
//

import FirebaseFirestore
import Foundation

class PastTripsViewModel: ObservableObject {
    @Published var showTripView: Bool = false
    @Published var selectedTrip: Trip? = nil
    @Published var tripToDelete: Trip? = nil
    @Published var showingDeleteConfirmation: Bool = false
}
