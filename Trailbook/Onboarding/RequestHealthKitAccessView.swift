//
//  RequestHealthKitAccessView.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/15/25.
//

import SwiftUI

struct RequestHealthKitAccessView: View {
    @ObservedObject public var healthKitManager: HealthKitManager
    @State private var isLoading: Bool = false

    var body: some View {
        VStack (spacing: 10) {
            Spacer()
            Image(systemName: "shoeprints.fill")
                .resizable()
                .frame(width: 150, height: 150)
                .padding(.vertical, 16)
            Text("HealthKit Access")
                .font(.largeTitle)
                .bold()
            Text("Trailbook uses HealthKit to log your daily steps.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Spacer()
            if (isLoading) {
                ProgressView()
            }
            Button {
                Task {
                    isLoading = true
                    await healthKitManager.requestHealthAuthorization()
                    isLoading = false
                }
            } label: {
                Text("Allow Access")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, maxHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
        }
        .padding(.horizontal, 16)
    }
}
