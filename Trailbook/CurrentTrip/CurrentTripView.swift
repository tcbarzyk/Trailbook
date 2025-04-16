//
//  CurrentTripView.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/14/25.
//

import SwiftUI

struct CurrentTripView: View {
    @ObservedObject public var userSession: UserSession
    @ObservedObject public var tripSession: TripSession
    @ObservedObject public var locationManager: LocationManager
    @ObservedObject public var healthKitManager: HealthKitManager

    @ObservedObject public var homeViewModel: HomeViewModel

    @StateObject private var vm = CurrentTripViewModel()

    var body: some View {
        if homeViewModel.isLoadingCurrentTrip {
            ProgressView()
        }
        else {
            ZStack {
                if let currentTrip = tripSession.currentTrip {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Current Trip:")
                            .font(.title)
                            .bold()
                        Text(currentTrip.title)
                            .font(.largeTitle)
                            .bold()
                        Text("Start date: \(currentTrip.startDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.title2)
                        if let endDate = currentTrip.endDate {
                            Text("End date: \(endDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.title2)
                        }
                        switch vm.state {
                        case .idle:
                            EmptyView()
                        case .loading:
                            EmptyView()
                        case .success:
                            EmptyView()
                        case .error(let error):
                            Text(error.localizedDescription)
                        }
                        Spacer()

                        // MARK: - Button Logic

                        let calendar = Calendar.current

                        // 1) Convert each date to midnight
                        let truncatedToday = calendar.startOfDay(for: Date())
                        let truncatedStart = calendar.startOfDay(for: currentTrip.startDate)
                        let truncatedEnd = currentTrip.endDate.map { calendar.startOfDay(for: $0) }
                        HStack {
                            Spacer()
                            // 1) If too early
                            if truncatedToday < truncatedStart {
                                VStack {
                                    Text("Come back when the trip starts to add your first entry!")
                                        .frame(maxWidth: 250)
                                        .font(.title3)
                                        .multilineTextAlignment(.center)
                                    Button {
                                        vm.endTripNotStarted(tripSession: tripSession)
                                    } label: {
                                        Image(systemName: "x.square.fill")
                                            .resizable()
                                            .frame(width: 100, height: 100)
                                            .foregroundStyle(.red)
                                    }
                                    .disabled(vm.isLoading)
                                    Text("Cancel Trip")
                                        .bold()
                                }
                                .padding(.bottom, 100)
                                Spacer()
                            }

                            // 2) If end exists and today > end => too late
                            else if let end = truncatedEnd, truncatedToday > end {
                                VStack {
                                    Text("Trip is over!")
                                        .bold()
                                        .font(.title)
                                    Button {
                                        Task {
                                            await vm.endTripAlreadyOver(tripSession: tripSession, homeViewModel: homeViewModel, userSession: userSession)
                                        }
                                    } label: {
                                        Image(systemName: "x.square.fill")
                                            .resizable()
                                            .frame(width: 100, height: 100)
                                            .foregroundStyle(.red)
                                    }
                                    .disabled(vm.isLoading)
                                    Text("End Trip")
                                        .bold()
                                }
                                .padding(.bottom, 100)
                                Spacer()
                            }

                            // 3) Otherwise => in range
                            else {
                                // "Add Entry"
                                VStack {
                                    Button {
                                        vm.showDayEntryView.toggle()
                                    } label: {
                                        Image(systemName: "plus.square.fill")
                                            .resizable()
                                            .frame(width: 100, height: 100)
                                    }
                                    .disabled(vm.isLoading || tripSession.addedDayEntry)
                                    if !tripSession.addedDayEntry {
                                        Text("Add Entry")
                                            .bold()
                                    }
                                    else {
                                        Text("Already added day entry!")
                                            .bold()
                                    }
                                }
                                .padding(.bottom, 100)
                                Spacer()

                                // "End Trip"
                                VStack {
                                    Button {
                                        Task {
                                            await vm.endTripInProgress(tripSession: tripSession, homeViewModel: homeViewModel, userSession: userSession)
                                        }
                                    } label: {
                                        Image(systemName: "x.square.fill")
                                            .resizable()
                                            .frame(width: 100, height: 100)
                                            .foregroundStyle(.red)
                                    }
                                    .disabled(vm.isLoading)
                                    Text("End Trip")
                                        .bold()
                                }
                                .padding(.bottom, 100)
                                Spacer()
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                }
                else {
                    VStack {
                        Text("No trip in progress")
                            .font(.title)
                        Button {
                            vm.creatingNewTrip.toggle()
                        } label: {
                            Image(systemName: "plus.square.fill")
                                .resizable()
                                .frame(width: 100, height: 100)
                        }
                        Text("Start Trip")
                            .bold()
                    }
                }
            }
            .sheet(isPresented: $vm.creatingNewTrip) {
                NewTripView(userSession: userSession, tripSession: tripSession, currentTripViewModel: vm)
            }
            .fullScreenCover(isPresented: $vm.showDayEntryView) {
                DayEntryView(tripSession: tripSession, currentTripViewModel: vm, locationManager: locationManager, healthKitManager: healthKitManager)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CurrentTripView(userSession: UserSession(), tripSession: TripSession.preview, locationManager: LocationManager(), healthKitManager: HealthKitManager(), homeViewModel: HomeViewModel())
    }
}

/*
 if trip not started -> end trip, delete the trip entirely
 if trip in progress -> end trip, set isCompleted = true, and set end date to current date
 if trip already over -> end trip, set isCompleted = true
 */
