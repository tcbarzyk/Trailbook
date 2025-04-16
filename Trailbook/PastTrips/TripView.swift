//
//  TripView.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/15/25.
//

import SwiftUI

struct TripView: View {
    @ObservedObject public var pastTripsViewModel: PastTripsViewModel
    @ObservedObject public var imageCacheManager: ImageCacheManager
    let trip: Trip

    @StateObject private var vm = TripViewModel()

    // 1) State for full-screen photo
    @State private var selectedURL: URL? = nil

    var body: some View {
        ZStack {
            Color.blue.ignoresSafeArea()

            if vm.isLoading {
                ProgressView()
            } else {
                TabView {
                    IntroTripCardView(trip: trip)
                    ForEach(vm.dayEntries.sorted { $0.date < $1.date }) { entry in
                        DayEntryCardView(entry: entry, imageCacheManager: imageCacheManager) { tappedURL in
                            selectedURL = tappedURL
                        }
                    }
                }
                .tabViewStyle(.page)
                //.indexViewStyle(.page(backgroundDisplayMode: .interactive))
            }

            // 3) Fullscreen overlay if selectedURL is set
            if let url = selectedURL {
                imageOverlay(url: url)
            }

            // (Existing close button, etc.)
            VStack(alignment: .leading) {
                Spacer()
                HStack {
                    Button {
                        pastTripsViewModel.showTripView = false
                    } label: {
                        Text("Close")
                            .padding(10)
                            .font(.title3)
                            .background(.white)
                            .cornerRadius(10)
                            .padding()
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            Task {
                vm.state = .loading
                do {
                    try await vm.fetchDayEntries(forTrip: trip.id ?? "")

                    // Collect all unique photo URLs from the day entries
                    let allPhotoURLs = vm.dayEntries
                        .flatMap { $0.photoURLs }
                        .uniqued() // You can define an extension for uniqueness or use Set

                    // Preload them using the cache manager
                    await imageCacheManager.preloadImages(for: allPhotoURLs)
                    
                    vm.state = .success
                    
                } catch {
                    vm.state = .error(error: error)
                }
            }
        }
    }

    // The overlay that covers the entire screen
    @ViewBuilder
    private func imageOverlay(url: URL) -> some View {
        ZStack {
            Color.black
                .opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture {
                    selectedURL = nil
                }

            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .tint(.white)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .padding()
                        // Also allow tapping the image to dismiss
                        .onTapGesture {
                            selectedURL = nil
                        }
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.white.opacity(0.7))
                        .padding()
                @unknown default:
                    EmptyView()
                }
            }
        }
        .transition(.opacity)
    }
}

struct IntroTripCardView: View {
    let trip: Trip
    var body: some View {
        VStack(spacing: 10) {
            Text(trip.title)
                .font(.largeTitle)
                .bold()
            Text("\(trip.startDate.formatted(date: .numeric, time: .omitted)) - \(trip.endDate?.formatted(date: .numeric, time: .omitted) ?? "")")
                .font(.title)
            Text("Swipe left to start viewing your entries for each day.")
                .multilineTextAlignment(.center)
        }
        .padding()
        .foregroundStyle(.white)
    }
}

struct DayEntryCardView: View {
    let entry: DayEntry
    
    @ObservedObject public var imageCacheManager: ImageCacheManager

    // Closure for tapping an image (this might pass a URL or cached UIImage)
    var onImageTap: (URL) -> Void

    var body: some View {
        //VStack(alignment: .leading, spacing: 10) {
            

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Entry for \(entry.date.formatted(date: .numeric, time: .omitted))")
                        .font(.largeTitle)
                        .bold()

                    Divider()
                        .overlay(Color.white)
                    
                    if !entry.photoURLs.isEmpty {
                        let photos = Array(entry.photoURLs.prefix(4))
                        let columns = [GridItem(.flexible()), GridItem(.flexible())]

                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(Array(photos.enumerated()), id: \.offset) { _, urlString in
                                if let url = URL(string: urlString) {
                                    // Check our custom cache first
                                    if let cachedImage = imageCacheManager.imageCache[urlString] {
                                        Image(uiImage: cachedImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 100)
                                            .clipped()
                                            .contentShape(Rectangle())
                                            .onTapGesture { onImageTap(url) }
                                    } else {
                                        // Fall back to AsyncImage if not cached.
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(height: 100)
                                                    .clipped()
                                                    .contentShape(Rectangle())
                                                    .onTapGesture { onImageTap(url) }
                                            case .failure:
                                                Image(systemName: "photo.badge.exclamationmark.fill")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: 100)
                                                    .foregroundStyle(Color.white.opacity(0.7))
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                    }
                                } else {
                                    Image(systemName: "photo.badge.exclamationmark.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 100)
                                        .foregroundStyle(Color.white.opacity(0.7))
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    
                    Divider()
                        .overlay(.white)

                    // Info
                    Text("Info")
                        .font(.title2)
                        .bold()

                    if let location = entry.location {
                        Text("**Location:** \(location)")
                    }
                    if let weather = entry.weather {
                        Text("**Weather:** \(weather)")
                    }
                    if let steps = entry.steps {
                        Text("**Steps:** \(steps)")
                    }

                    Divider()
                        .overlay(.white)

                    // Moments
                    Text("Moments")
                        .font(.title2)
                        .bold()

                    ForEach(entry.moments) { moment in
                        Text(moment.prompt)
                            .bold()
                        Text(moment.response)
                    }

                    Divider()
                        .overlay(.white)
                        .padding(.bottom, 80)
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 15)
        //}
    }
}

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

/*
 #Preview {
     ZStack {
         Color.blue.ignoresSafeArea()
         //DayEntryCardView(entry: DayEntry.sample)
         IntroTripCardView(trip: Trip.sample)
     }
 }
 */

#Preview {
    ContentView()
}

