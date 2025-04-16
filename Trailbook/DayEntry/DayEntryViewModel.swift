//
//  DayEntryViewModel.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/14/25.
//
import FirebaseFirestore
import FirebaseStorage
import Foundation
import PhotosUI
import SwiftUI

@MainActor
class DayEntryViewModel: ObservableObject {
    @Published var date = Date()
    // @Published var steps: Int = 0
    @Published var weather: String = ""
    @Published var location: String = ""
    
    @Published var moments: [Moment] = [
        Moment(prompt: "What was your favorite meal today?", response: ""),
        Moment(prompt: "Where did you go or explore?", response: ""),
        Moment(prompt: "What surprised you today?", response: ""),
        Moment(prompt: "Who did you meet or talk to?", response: ""),
        Moment(prompt: "What did you try for the first time?", response: ""),
        Moment(prompt: "What was the most beautiful thing you saw?", response: ""),
        Moment(prompt: "Any other extra notes?", response: ""),
    ]

    @Published var photoURLs: [String] = []
    @Published var selectedPhotoItems: [PhotosPickerItem] = []
    @Published var selectedImages: [UIImage] = []
    
    @Published var state: LoadingState = .idle
    var isLoading: Bool {
        if case .loading = state {
            return true
        } else if !(hasFetchedLocationAndWeather && hasFetchedSteps) {
            return true
        }
        return false
    }

    @Published var hasFetchedLocationAndWeather = false
    @Published var hasFetchedSteps = false
    @Published var photosConverted = true
    
    func fetchWeather(latitude: Double, longitude: Double) async {
        if let apiKey = Bundle.main.infoDictionary?["OpenWeatherAPIKey"] as? String {
            print("Loaded API key")
            let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=metric"
                
            guard let url = URL(string: urlString) else { return }
                
            do {
                // 1) Make the network request
                let (data, _) = try await URLSession.shared.data(from: url)
                    
                // 2) Decode JSON
                let decodedResponse = try JSONDecoder().decode(OWWeatherResponse.self, from: data)
                    
                // 3) Update @Published properties
                weather = decodedResponse.weather.first?.description ?? ""
            } catch {
                print("Error fetching OpenWeather data: \(error)")
            }
        } else {
            print("API key not found")
            return
        }
    }
    
    func uploadPhotos(tripId: String) async throws {
        let storage = Storage.storage()
        
        // Use a loop to iterate over the images
        for (index, image) in selectedImages.enumerated() {
            // Convert UIImage to JPEG Data (or PNG if you prefer)
            guard let data = image.jpegData(compressionQuality: 0.5) else { continue }
            
            // Create a unique reference for each image
            let photoRef = storage.reference().child("day_entries/\(tripId)/\(date.formatted(date: .numeric, time: .omitted))/photo_\(index).jpg")
            
            // Upload the data
            let _ = try await photoRef.putDataAsync(data, metadata: nil)
            
            // Once uploaded, retrieve the download URL
            let url = try await photoRef.downloadURL()
            photoURLs.append(url.absoluteString)
        }
    }
    
    func addDayEntry(to tripId: String, entry: DayEntry) throws {
        let db = Firestore.firestore()
        try db.collection("trips")
            .document(tripId)
            .collection("days")
            .addDocument(from: entry)
    }
}
