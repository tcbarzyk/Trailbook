//
//  ImageCacheManager.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/16/25.
//

import SwiftUI

@MainActor
class ImageCacheManager: ObservableObject {
    @Published var imageCache: [String: UIImage] = [:]
    
    // Preload images for a given list of URL strings.
    func preloadImages(for urls: [String]) async {
        for urlStr in urls {
            guard let url = URL(string: urlStr) else { continue }
            // Skip if already cached
            if imageCache[urlStr] != nil { continue }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    imageCache[urlStr] = image
                }
            } catch {
                print("Error preloading image for url \(urlStr): \(error)")
            }
        }
    }
}
