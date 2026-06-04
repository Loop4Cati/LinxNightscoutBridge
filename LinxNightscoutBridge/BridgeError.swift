import Foundation

enum BridgeError: LocalizedError {
    case healthKitUnavailable
    case invalidNightscoutURL
    case nightscoutUploadFailed

    var errorDescription: String? {
        switch self {
        case .healthKitUnavailable:
            return "HealthKit nu este disponibil sau tipul Blood Glucose nu poate fi accesat."
        case .invalidNightscoutURL:
            return "URL-ul Nightscout nu este valid."
        case .nightscoutUploadFailed:
            return "Nightscout a refuzat upload-ul. Verifică URL-ul și API_SECRET."
        }
    }
}
