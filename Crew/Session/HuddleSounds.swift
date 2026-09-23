import AVFoundation
import Foundation

enum HuddleSounds {
    static func join() { play(notes: [587.33, 880]) }
    static func leave() { play(notes: [587.33, 392]) }

    private static func play(notes: [Double]) {
        let sampleRate = 44_100.0
        let noteLength = 0.22
        let gap = 0.09
        let total = gap * Double(max(notes.count - 1, 0)) + noteLength + 0.04
        let frameCount = AVAudioFrameCount(sampleRate * total)
        guard
            let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
            let samples = buffer.floatChannelData?[0]
        else { return }
        buffer.frameLength = frameCount
        for i in 0 ..< Int(frameCount) { samples[i] = 0 }

        for (index, frequency) in notes.enumerated() {
            let start = Int(sampleRate * gap * Double(index))
            let length = Int(sampleRate * noteLength)
            for n in 0 ..< length where start + n < Int(frameCount) {
                let t = Double(n) / sampleRate
                let env: Double
                if t < 0.015 {
                    env = t / 0.015
                } else if t > noteLength - 0.08 {
                    env = max(0, (noteLength - t) / 0.08)
                } else {
                    env = 1
                }
                samples[start + n] += Float(sin(2 * Double.pi * frequency * t) * env * 0.16)
            }
        }

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        let holder = EngineHolder(engine: engine, player: player)
        player.scheduleBuffer(buffer, completionHandler: {
            DispatchQueue.main.async { holder.stop() }
        })
        do {
            try engine.start()
            player.play()
            EngineHolder.keep(holder)
        } catch {
            return
        }
    }
}

private final class EngineHolder: @unchecked Sendable {
    static var live: [EngineHolder] = []
    let engine: AVAudioEngine
    let player: AVAudioPlayerNode

    init(engine: AVAudioEngine, player: AVAudioPlayerNode) {
        self.engine = engine
        self.player = player
    }

    static func keep(_ holder: EngineHolder) { live.append(holder) }

    func stop() {
        player.stop()
        engine.stop()
        EngineHolder.live.removeAll { $0 === self }
    }
}
