//
//  UserProfile.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/14/25.
//
import FirebaseFirestore

struct UserProfile: Codable {
    @DocumentID var id: String?
    var currentTripId: String?
}
