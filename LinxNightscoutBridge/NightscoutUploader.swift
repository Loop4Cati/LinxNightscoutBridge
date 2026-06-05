import Foundation
import CryptoKit

struct NightscoutEntry: Codable {
    let type: String
    let date: Int64
    let dateString: String
    let sgv: Int
    let direction: String
    let device: String
}

final class NightscoutUploader {
    func upload(reading: GlucoseReading, baseURL: String, apiSecret: String) async throws {
        try await upload(readings: [reading], baseURL: baseURL, apiSecret: apiSecret)
    }

    func upload(readings: [GlucoseReading], baseURL: String, apiSecret: String) async throws {
        guard !readings.isEmpty else { return }

        guard var components = URLComponents(string: baseURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw BridgeError.invalidNightscoutURL
        }

        components.path = "/api/v1/entries.json"
        guard let url = components.url else {
            throw BridgeError.invalidNightscoutURL
        }

        let formatter = ISO8601DateFormatter()

        let entries = readings.map { reading in
            NightscoutEntry(
                type: "sgv",
                date: Int64(reading.date.timeIntervalSince1970 * 1000),
                dateString: formatter.string(from: reading.date),
                sgv: Int(reading.valueMgdl.rounded()),
                direction: "Flat",
                device: "LinxNightscoutBridge"
            )
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(sha1(apiSecret), forHTTPHeaderField: "api-secret")
        request.httpBody = try JSONEncoder().encode(entries)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw BridgeError.nightscoutUploadFailed
        }
    }

    private func sha1(_ text: String) -> String {
        let data = Data(text.utf8)
        let digest = Insecure.SHA1.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
