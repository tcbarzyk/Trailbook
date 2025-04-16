//
//  Trip.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/14/25.
//

import Foundation
import FirebaseFirestore

struct Trip: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    
    var title: String
    var startDate: Date
    var endDate: Date?
    
    //var location: String?
    var createdAt: Date = Date()
    var isCompleted: Bool = false
}

extension Trip {
    static let sample = Trip(
        id: "sampleTrip123",
        userId: "sampleUser456",
        title: "Trip to New York",
        startDate: Date(timeIntervalSince1970: 1_708_000_000),
        endDate: Date(timeIntervalSince1970: 2_708_086_400),
        createdAt: Date(timeIntervalSince1970: 2_708_000_000),
        isCompleted: false
    )
}
