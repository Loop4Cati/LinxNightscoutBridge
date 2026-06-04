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
        guard let glucoseType else { throw BridgeError.healthKitUnavailable }

        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-24 * 60 * 60), end: Date(), options: [])

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: glucoseType, predicate: predicate, limit: 1, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let unit = HKUnit.gramUnit(with: .milli).unitDivided(by: HKUnit.literUnit(with: .deci))
                let value = sample.quantity.doubleValue(for: unit)
                continuation.resume(returning: GlucoseReading(valueMgdl: value, date: sample.endDate, uuid: sample.uuid))
            }
            self.store.execute(query)
        }
    }
}
