import Foundation
import AVFoundation

final class SilentTuneManager {
    static let shared = SilentTuneManager()

    private var player: AVAudioPlayer?

    private init() {}

    func start() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)

            let url = try makeSilentAudioFile()
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.volume = 0.01
            player?.play()
        } catch {
            print("SilentTune start failed: \(error)")
        }
    }

    func stop() {
        player?.stop()
        player = nil

        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("SilentTune stop failed: \(error)")
        }
    }

    private func makeSilentAudioFile() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("silent.caf")

        if FileManager.default.fileExists(atPath: url.path) {
            return url
        }

        let sampleRate = 44100.0
        let duration = 1.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        try file.write(from: buffer)

        return url
    }
}
