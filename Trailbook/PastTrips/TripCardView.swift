//
//  TripCardView.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/15/25.
//


//
//  IndividualTripView.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/15/25.
//
import SwiftUI

struct TripCardView: View {
    let trip: Trip
    var onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Text(trip.title)
                    .font(.headline)
                HStack {
                    Image(systemName: "calendar")
                    Text("\(trip.startDate.formatted(date: .numeric, time: .omitted)) - \(trip.endDate?.formatted(date: .numeric, time: .omitted) ?? "")")
                }
            }
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash.circle.fill")
                    .font(.largeTitle)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .red)
            }
            
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.blue)
        .foregroundStyle(.white)
        .cornerRadius(12)
    }
}

