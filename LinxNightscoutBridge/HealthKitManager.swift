import Foundation
import HealthKit

struct GlucoseReading: Equatable {
    let valueMgdl: Double
    let date: Date
    let uuid: UUID
}

final class HealthKitManager {
    private let store = HKHealthStore()

    private var glucoseType: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .bloodGlucose)
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable(), let glucoseType else {
            throw BridgeError.healthKitUnavailable
        }

        try await store.requestAuthorization(toShare: [], read: [glucoseType])
    }

    func latestBloodGlucose() async throws -> GlucoseReading? {
        let readings = try await bloodGlucoseReadings(
            from: Date().addingTimeInterval(-24 * 60 * 60),
            to: Date()
        )

        return readings.last
    }

    func bloodGlucoseReadings(from startDate: Date, to endDate: Date) async throws -> [GlucoseReading] {
        guard let glucoseType else {
            throw BridgeError.healthKitUnavailable
        }

        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: []
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: glucoseType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let unit = HKUnit.gramUnit(with: .milli)
                    .unitDivided(by: HKUnit.literUnit(with: .deci))

                let readings = (samples ?? [])
                    .compactMap { $0 as? HKQuantitySample }
                    .map {
                        GlucoseReading(
                            valueMgdl: $0.quantity.doubleValue(for: unit),
                            date: $0.endDate,
                            uuid: $0.uuid
                        )
                    }

                continuation.resume(returning: readings)
            }

            self.store.execute(query)
        }
    }
}
