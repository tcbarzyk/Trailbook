//
//  NewTripView.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/14/25.
//

import SwiftUI

struct NewTripView: View {
    @ObservedObject public var userSession: UserSession
    @ObservedObject public var tripSession: TripSession
    @ObservedObject public var currentTripViewModel: CurrentTripViewModel

    @StateObject private var vm = NewTripViewModel()

    private var canSaveTrip: Bool {
        let trimmedTitle = vm.titleInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            return false
        }
        if vm.hasEndDate && vm.endDateInput <= vm.startDateInput {
            return false
        }
        return true
    }

    var body: some View {
        VStack(spacing: 15) {
            // Spacer()
            Text("Start a Trip")
                .font(.largeTitle)
                .bold()
            HStack {
                Text("Title:")
                TextField("e.g. \"New York Trip\"", text: $vm.titleInput)
                    .textFieldStyle(.roundedBorder)
            }
            DatePicker(
                "Start Date:",
                selection: $vm.startDateInput,
                displayedComponents: .date
            )
            Toggle("Include End Date", isOn: $vm.hasEndDate)
            DatePicker(
                "End Date:",
                selection: $vm.endDateInput,
                displayedComponents: .date
            )
            .disabled(!vm.hasEndDate)
            // Spacer()
            Button {
                handleSaveTrip()
            } label: {
                Text("Save")
                    .font(.title3)
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.isLoading || !canSaveTrip)

            switch vm.state {
            case .idle:
                EmptyView()
            case .loading:
                ProgressView()
            case .success:
                EmptyView()
            case .error(let error):
                Text(error.localizedDescription)
            }
        }
        .padding(.horizontal)
        .onChange(of: vm.isSuccessful) { _ in
            currentTripViewModel.creatingNewTrip = false
        }
    }

    func handleSaveTrip() {
        let trimmedTitle = vm.titleInput.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate title is not empty
        guard !trimmedTitle.isEmpty else {
            vm.state = .error(error: NSError(domain: "NewTripError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Title cannot be empty"]))
            return
        }

        // Validate end date if enabled
        if vm.hasEndDate {
            guard vm.endDateInput > vm.startDateInput else {
                vm.state = .error(error: NSError(domain: "NewTripError", code: 2, userInfo: [NSLocalizedDescriptionKey: "End Date must be after Start Date"]))
                return
            }
        }

        let trip = Trip(
            userId: userSession.user?.uid ?? "",
            title: trimmedTitle,
            startDate: vm.startDateInput,
            endDate: vm.hasEndDate ? vm.endDateInput : nil
        )
        vm.saveTrip(trip: trip, userId: userSession.user?.uid ?? "", tripSession: tripSession)
    }
}

#Preview {
    NavigationStack {
        NewTripView(userSession: UserSession(), tripSession: TripSession(), currentTripViewModel: CurrentTripViewModel())
    }
}
