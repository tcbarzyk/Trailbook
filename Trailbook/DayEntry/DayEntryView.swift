//
//  DayEntryView.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/14/25.
//
import PhotosUI
import SwiftUI

struct DayEntryView: View {
    // @ObservedObject public var userSession: UserSession
    @ObservedObject public var tripSession: TripSession
    @ObservedObject public var currentTripViewModel: CurrentTripViewModel
    @ObservedObject public var locationManager: LocationManager
    @ObservedObject public var healthKitManager: HealthKitManager

    @StateObject private var vm = DayEntryViewModel()

    var body: some View {
        ZStack {
            Color.blue
                .ignoresSafeArea()

            if !vm.isLoading {
                TabView {
                    IntroCardView()
                    LocationCardView(dayEntryViewModel: vm)
                    WeatherCardView(dayEntryViewModel: vm)
                    if healthKitManager.steps != 0 {
                        StepsCardView(healthKitManager: healthKitManager)
                    }
                    PhotoCardView(dayEntryViewModel: vm)
                    ForEach($vm.moments) { $moment in
                        PromptCardView(moment: $moment)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .interactive))
            } else {
                ProgressView()
                    .tint(.white)
            }

            VStack {
                Spacer()
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
                HStack {
                    Button("Cancel") {
                        currentTripViewModel.showDayEntryView = false
                    }
                    .padding(10)
                    .font(.title3)
                    .background(.white)
                    .cornerRadius(10)
                    .padding()
                    .disabled(vm.isLoading)
                    Spacer()
                    Button("Finish") {
                        Task {
                            await handleFinishDayEntry()
                        }
                    }
                    .padding(10)
                    .font(.title3)
                    .background(.white)
                    .cornerRadius(10)
                    .padding()
                    .disabled(vm.isLoading || !vm.photosConverted)
                }
            }
        }
        .onAppear {
            locationManager.startFetchingCurrentLocation()
            Task {
                await healthKitManager.calculateSteps()
                //vm.steps = healthKitManager.steps
                vm.hasFetchedSteps = true
            }
        }
        // (2) When the view disappears, stop updates
        .onDisappear {
            locationManager.stopFetchingCurrentLocation()
        }
        // (3) React to changes in `lastKnownPlacemark` (or userLocation if you prefer)
        .onReceive(locationManager.$lastKnownPlacemark) { placemark in
            guard let placemark = placemark, !vm.hasFetchedLocationAndWeather else { return }

            let city = placemark.locality ?? ""

            Task {
                vm.location = city

                if let loc = locationManager.userLocation {
                    await vm.fetchWeather(latitude: loc.coordinate.latitude,
                                          longitude: loc.coordinate.longitude)
                }

                vm.hasFetchedLocationAndWeather = true
            }
        }
    }

    func handleFinishDayEntry() async {
        vm.state = .loading
        do {
            // 1) Ensure we have a current trip & ID
            guard let trip = tripSession.currentTrip else {
                throw NSError(domain: "DayEntryError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get current trip"])
            }
            guard let tripId = trip.id else {
                throw NSError(domain: "DayEntryError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to get current trip ID"])
            }

            // 2) Upload photos
            try await vm.uploadPhotos(tripId: tripId)

            // 3) Filter out empty responses / zero values
            let filteredMoments = vm.moments.filter {
                !$0.response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            let finalSteps: Int? = healthKitManager.steps == 0 ? nil : healthKitManager.steps
            let finalWeather: String? = vm.weather.isEmpty ? nil : vm.weather
            let finalLocation: String? = vm.location.isEmpty ? nil : vm.location

            // 4) Construct the DayEntry
            let dayEntry = DayEntry(
                date: vm.date,
                steps: finalSteps,
                weather: finalWeather,
                location: finalLocation,
                moments: filteredMoments,
                photoURLs: vm.photoURLs
            )

            // 5) Write the DayEntry to Firestore
            try vm.addDayEntry(to: tripId, entry: dayEntry)

            // 6) If we reach here, everything worked
            vm.state = .success
            currentTripViewModel.showDayEntryView = false
            tripSession.addedDayEntry = true

        } catch {
            // Any error from steps 1–5 is caught here
            print("Error finishing day entry: \(error.localizedDescription)")
            vm.state = .error(error: error)
        }
    }
}

struct IntroCardView: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("Day Entry")
                .font(.largeTitle)
                .bold()
                .foregroundStyle(.white)
            Text(Date.now.formatted(date: .abbreviated, time: .omitted))
                .font(.title)
                .foregroundStyle(.white)
            Text("Swipe left to start documenting your day.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
        }
        .padding()
    }
}

struct LocationCardView: View {
    @ObservedObject public var dayEntryViewModel: DayEntryViewModel
    var body: some View {
        VStack {
            Text("You ended the day in...")
                .font(.title2)
                .foregroundStyle(.white)
            Text("\(dayEntryViewModel.location)")
                .bold()
                .font(.largeTitle)
                .foregroundStyle(.white)
        }
    }
}

struct WeatherCardView: View {
    @ObservedObject public var dayEntryViewModel: DayEntryViewModel
    var body: some View {
        VStack {
            Text("The weather today was...")
                .font(.title2)
                .foregroundStyle(.white)
            Text("\(dayEntryViewModel.weather)")
                .bold()
                .font(.largeTitle)
                .foregroundStyle(.white)
        }
    }
}

struct StepsCardView: View {
    //@ObservedObject public var dayEntryViewModel: DayEntryViewModel
    @ObservedObject public var healthKitManager: HealthKitManager
    var body: some View {
        VStack {
            Text("Today, you took...")
                .font(.title2)
                .foregroundStyle(.white)
            Text("\(healthKitManager.steps) steps")
                .bold()
                .font(.largeTitle)
                .foregroundStyle(.white)
        }
    }
}

struct PromptCardView: View {
    @Binding var moment: Moment

    var body: some View {
        VStack(spacing: 16) {
            Text(moment.prompt)
                .font(.title3)
                .bold()
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            TextEditor(text: $moment.response)
                .frame(height: 100)
                .scrollContentBackground(.hidden)
                .background(.white)
                .foregroundStyle(.black)
                .cornerRadius(8)
        }
        .padding()
    }
}

struct PhotoCardView: View {
    @ObservedObject public var dayEntryViewModel: DayEntryViewModel
    // var onComplete: ([UIImage]) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Upload up to 4 photos from your day")
                .bold()
                .font(.largeTitle)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            PhotosPicker(
                selection: $dayEntryViewModel.selectedPhotoItems,
                maxSelectionCount: 4,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Text("Choose Photos")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            .onChange(of: dayEntryViewModel.selectedPhotoItems) { newItems in
                // Clear previous selections
                dayEntryViewModel.selectedImages = []
                dayEntryViewModel.photosConverted = false

                // Convert each selected item to UIImage (asynchronously)
                for item in newItems {
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data)
                        {
                            await MainActor.run {
                                dayEntryViewModel.selectedImages.append(uiImage)
                                // When complete, call onComplete if needed:
                                if dayEntryViewModel.selectedImages.count == newItems.count {
                                    dayEntryViewModel.photosConverted = true
                                    // onComplete(dayEntryViewModel.selectedImages)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CurrentTripView(userSession: UserSession(), tripSession: TripSession.preview, locationManager: LocationManager(), healthKitManager: HealthKitManager(), homeViewModel: HomeViewModel())
    }
}
