import Foundation
import SwiftUI

@MainActor
final class SyncService: ObservableObject {
    @Published var lastMessage: String?

    private let health = HealthKitManager()
    private let uploader = NightscoutUploader()

    @AppStorage("nightscoutURL") private var nightscoutURL = ""
    @AppStorage("apiSecret") private var apiSecret = ""
    @AppStorage("lastUploadedHealthKitUUID") private var lastUploadedHealthKitUUID = ""

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
            guard let reading = try await health.latestBloodGlucose() else {
                lastMessage = "Nu am găsit valori de glicemie în ultimele 24h."
                return
            }

            if reading.uuid.uuidString == lastUploadedHealthKitUUID {
                lastMessage = "Valoarea există deja: \(Int(reading.valueMgdl.rounded())) mg/dL."
                return
            }

            try await uploader.upload(reading: reading, baseURL: nightscoutURL, apiSecret: apiSecret)
            lastUploadedHealthKitUUID = reading.uuid.uuidString
            lastMessage = "Trimis: \(Int(reading.valueMgdl.rounded())) mg/dL."
        } catch {
            lastMessage = "Eroare sync: \(error.localizedDescription)"
        }
    }
}
