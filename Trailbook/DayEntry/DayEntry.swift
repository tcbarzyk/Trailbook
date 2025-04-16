//
//  DayEntry.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/14/25.
//

import Foundation
import FirebaseFirestore

struct DayEntry: Identifiable, Codable {
    @DocumentID var id: String?
    var date: Date
    var steps: Int?
    var weather: String?
    var location: String?
    var moments: [Moment] = []
    var photoURLs: [String] = []
}

extension DayEntry {
    static let sample = DayEntry(
        id: "sampleDayEntry01",
        date: Date(timeIntervalSince1970: 1680000000), // Adjust the date as needed
        steps: 7500,
        weather: "Sunny",
        location: "San Francisco",
        moments: [
            Moment(prompt: "Favorite meal and where?", response: "Had a delicious burger at Joe’s Diner"),
            Moment(prompt: "Most memorable moment?", response: "Watched a breathtaking sunset over the bay")
        ],
        photoURLs: [
            "https://upload.wikimedia.org/wikipedia/commons/1/15/Cat_August_2010-4.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/6/68/Orange_tabby_cat_sitting_on_fallen_leaves-Hisashi-01A.jpg",
            "https://upload.wikimedia.org/wikipedia/commons/b/b6/Felis_catus-cat_on_snow.jpg"
        ]
    )
}
