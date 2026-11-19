import Foundation
import AVFoundation

final class SpeechService {
    static let shared = SpeechService()
    private let synthesizer = AVSpeechSynthesizer()

    private init() {}

    func speak(_ word: String) {
        guard !word.isEmpty else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true, options: [])
        } catch {
            // Speech still works in most cases even if audio session setup fails.
        }
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: word)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.45
        utterance.pitchMultiplier = 1.0
        synthesizer.speak(utterance)
    }
}
