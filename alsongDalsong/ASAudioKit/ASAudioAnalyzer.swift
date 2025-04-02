import ASLogKit
import AVFoundation
import Foundation

public enum ASAudioAnalyzer {
    public static func analyze(data: Data, count: Int) async throws -> [CGFloat] {
        do {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
            try data.write(to: tempURL)
            let file = try AVAudioFile(forReading: tempURL)

            guard
                let format = AVAudioFormat(
                    commonFormat: .pcmFormatFloat32,
                    sampleRate: file.fileFormat.sampleRate,
                    channels: file.fileFormat.channelCount,
                    interleaved: false
                ),
                let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(file.length))
            else {
                return []
            }

            try file.read(into: buffer)
            
            guard let floatChannelData = buffer.floatChannelData else { return [] }

            let frameLength = Int(buffer.frameLength)
            let samples = Array(UnsafeBufferPointer(start: floatChannelData[0], count: frameLength))
            
            try? FileManager.default.removeItem(at: tempURL)
            
            return downSample(samples, count: count)
        } catch {
            ErrorHandler.handle(error)
            throw ASAudioError.analyzeAudio
        }
    }
    
    private static func downSample(_ samples: [Float], count: Int) -> [CGFloat] {
        let chunk = samples.count / count
        var downSamples: [CGFloat] = []

        for i in 0..<count {
            let start = i * chunk
            let end = min((i + 1) * chunk, samples.count)
            let chunkSamples = samples[start..<end]
            
            downSamples.append(CGFloat(chunkSamples.max() ?? 0))
        }
        
        return downSamples
    }
}
