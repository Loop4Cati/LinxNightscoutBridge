import Foundation
import SwiftUI

@MainActor
final class SyncService: ObservableObject {
    @Published var lastMessage: String?

    private let health = HealthKitManager()
    private let uploader = NightscoutUploader()

    @AppStorage("nightscoutURL") private var nightscoutURL = ""
    @AppStorage("apiSecret") private var apiSecret = ""
    @AppStorage("lastUploadedDate") private var lastUploadedDate: Double = 0

    func requestHealthPermission() async {
        do {
            try await health.requestAuthorization()
            lastMessage = "Permisiune HealthKit acordată."
        } catch {
            lastMessage = "Eroare HealthKit: \(error.localizedDescription)"
        }
    }

    func syncLatestGlucose() async {
        do {
            let startDate: Date

            if lastUploadedDate > 0 {
                startDate = Date(timeIntervalSince1970: lastUploadedDate)
            } else {
                startDate = Date().addingTimeInterval(-24 * 60 * 60)
            }

            let readings = try await health.bloodGlucoseReadings(from: startDate, to: Date())

            guard !readings.isEmpty else {
                lastMessage = "Nu sunt valori noi de sincronizat."
                return
            }

            try await uploader.upload(readings: readings, baseURL: nightscoutURL, apiSecret: apiSecret)

            if let newest = readings.map(\.date).max() {
                lastUploadedDate = newest.timeIntervalSince1970
            }

            lastMessage = "Sincronizate \(readings.count) valori."
        } catch {
            lastMessage = "Eroare sync: \(error.localizedDescription)"
        }
    }

    func resetSyncHistory() {
        lastUploadedDate = 0
        lastMessage = "Istoricul de sincronizare a fost resetat."
    }
}
