//
//  PastTripsView.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/15/25.
//

import FirebaseFirestore
import FirebaseStorage
import SwiftUI

struct PastTripsView: View {
    @ObservedObject public var tripSession: TripSession
    @ObservedObject public var homeViewModel: HomeViewModel
    @ObservedObject public var imageCacheManager: ImageCacheManager

    @StateObject private var vm = PastTripsViewModel()

    var body: some View {
        if homeViewModel.isLoadingPastTrips {
            ProgressView()
        } else {
            VStack(alignment: .leading) {
                Text("Past Trips")
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal, 15)
                ScrollView {
                    ForEach(self.tripSession.pastTrips.sorted(by: { $0.startDate > $1.startDate })) { trip in
                        Button {
                            self.vm.selectedTrip = trip
                            self.vm.showTripView = true
                        } label: {
                            TripCardView(trip: trip) {
                                self.confirmDelete(trip: trip)
                            }
                            .padding(.horizontal, 15)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .fullScreenCover(isPresented: $vm.showTripView) {
                if let trip = vm.selectedTrip {
                    TripView(pastTripsViewModel: self.vm, imageCacheManager: imageCacheManager, trip: trip)
                } else {
                    // Fallback if no trip is selected (should not happen if button action works)
                    Text("No trip selected")
                }
            }
            .confirmationDialog("Are you sure you want to delete this trip?", isPresented: $vm.showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let trip = vm.tripToDelete {
                        deleteTrip(trip: trip)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    func confirmDelete(trip: Trip) {
        vm.tripToDelete = trip
        vm.showingDeleteConfirmation = true
    }

    func deleteTrip(trip: Trip) {
        guard let tripId = trip.id else {
            print("Error: no tripId found.")
            return
        }

        let db = Firestore.firestore()

        // 1) First, delete all the images stored under the trip folder (you already have a recursive delete function)
        recursivelyDeleteTripFolder(tripId: tripId) { error in
            if let error = error {
                print("Error deleting trip folder: \(error.localizedDescription)")
                // Decide here if you want to proceed with deleting Firestore data or not.
            }
            
            // 2) Next, delete the "days" subcollection for this trip
            self.deleteDaysSubcollection(tripId: tripId) { error in
                if let error = error {
                    print("Error deleting days subcollection: \(error.localizedDescription)")
                    // You might choose to proceed, or handle the error as needed.
                }
                
                // 3) Finally, delete the trip document itself
                db.collection("trips").document(tripId).delete { error in
                    if let error = error {
                        print("Error deleting trip document: \(error.localizedDescription)")
                    } else {
                        print("Trip document successfully deleted")
                        DispatchQueue.main.async {
                            self.tripSession.pastTrips.removeAll { $0.id == tripId }
                        }
                    }
                }
            }
        }
    }

    
    func deleteDaysSubcollection(tripId: String, completion: @escaping (Error?) -> Void) {
        let db = Firestore.firestore()
        let daysRef = db.collection("trips").document(tripId).collection("days")
        
        daysRef.getDocuments { snapshot, error in
            if let error = error {
                completion(error)
                return
            }
            guard let snapshot = snapshot else {
                completion(nil)
                return
            }
            
            // Use a DispatchGroup to wait for all deletions to complete.
            let group = DispatchGroup()
            for document in snapshot.documents {
                group.enter()
                document.reference.delete { err in
                    if let err = err {
                        print("Error deleting day document: \(err.localizedDescription)")
                    }
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                completion(nil)
            }
        }
    }


    func recursivelyDeleteTripFolder(tripId: String, completion: @escaping (Error?) -> Void) {
        let folderRef = Storage.storage().reference()
            .child("day_entries")
            .child(tripId)

        recursivelyDeleteFolderContents(folderRef) { error in
            completion(error)
        }
    }

    // Helper function that walks the subfolders and deletes everything
    private func recursivelyDeleteFolderContents(_ folderRef: StorageReference,
                                                 completion: @escaping (Error?) -> Void)
    {
        folderRef.listAll { result, error in
            if let error = error {
                completion(error)
                return
            }

            guard let result = result else {
                // No contents
                completion(nil)
                return
            }

            // 1) Delete all items at this level
            let group = DispatchGroup()

            for item in result.items {
                group.enter()
                item.delete { err in
                    if let err = err {
                        print("Error deleting item: \(err.localizedDescription)")
                    }
                    group.leave()
                }
            }

            // 2) Recursively handle each subfolder
            for prefixRef in result.prefixes {
                group.enter()
                recursivelyDeleteFolderContents(prefixRef) { err in
                    if let err = err {
                        print("Error deleting subfolder: \(err.localizedDescription)")
                    }
                    group.leave()
                }
            }

            // 3) When all deletions finish, call completion
            group.notify(queue: .main) {
                completion(nil)
            }
        }
    }
}

/*
  Past trips view:
 in tripSession, store array of all past trips
  when home view appears, get past trips from server and store in that array
  display past trips in a list in PastTripsView
     -each past trip shows: trip title, start and end date, and number of day entries
  when past trip is tapped, the user is presented with a swipable interface, so they can swipe through and view each day of the trip
  user has the option to delete entire trip, but cannot edit it
  when the user ends a trip in progress, PastTripsView should update to show it
  */

#Preview {
    ContentView()
}
