//
//  RequestLocationAccessView.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/14/25.
//
import SwiftUI

struct RequestLocationAccessView: View {
    @ObservedObject public var locationManager: LocationManager

    var body: some View {
        VStack (spacing: 10) {
            Spacer()
            Image(systemName: "globe")
                .resizable()
                .frame(width: 150, height: 150)
                .padding(.vertical, 16)
            Text("Location Access")
                .font(.largeTitle)
                .bold()
            Text("Trailbook uses your location to log your daily travel.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Spacer()
            Button {
                locationManager.requestLocationAccess()
            } label: {
                Text("Allow Access")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, maxHeight: 50)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    RequestLocationAccessView(locationManager: LocationManager())
}
