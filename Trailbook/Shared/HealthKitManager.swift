//
//  HealthKitManager.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/15/25.
//
import HealthKit

@MainActor
class HealthKitManager: ObservableObject {
    private let store = HKHealthStore()
    @Published var steps: Int = 0
    @Published var healthKitAuthorized: Bool = false

    func requestHealthAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            healthKitAuthorized = true
            return
        }
        
        // Request authorization to read the user's step count from HealthKit
        try? await HKHealthStore().requestAuthorization(toShare: [], read: [HKQuantityType(.stepCount)])
        healthKitAuthorized = true
    }

    public func calculateSteps() async {
        // To get the day's steps, start from midnight and end now
        let dateEnd = Date.now
        let dateStart = Calendar.current.startOfDay(for: .now)

        // To get daily steps data
        let dayComponent = DateComponents(day: 1)

        let predicate = HKQuery.predicateForSamples(withStart: dateStart, end: dateEnd, options: .strictStartDate)
        let samplePredicate = HKSamplePredicate.quantitySample(type: HKQuantityType(.stepCount), predicate: predicate)

        let descriptor = HKStatisticsCollectionQueryDescriptor(
            predicate: samplePredicate, options: .cumulativeSum, anchorDate: dateStart, intervalComponents: dayComponent
        )

        let result = try? await descriptor.result(for: HKHealthStore())

        // From the daily steps data, get today's step count samples
        result?.enumerateStatistics(from: dateStart, to: dateEnd) { statistics, _ in
            // Sum up all step samples for the day
            let steps = Int(statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0)
            DispatchQueue.main.async {
                self.steps = steps
            }
        }
    }
}
