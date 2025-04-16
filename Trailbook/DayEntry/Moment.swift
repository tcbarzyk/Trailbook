//
//  Moment.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/14/25.
//

import Foundation

struct Moment: Codable, Identifiable {
    var id: UUID = UUID()
    var prompt: String
    var response: String
    var photoURL: String? // optional photo
}
