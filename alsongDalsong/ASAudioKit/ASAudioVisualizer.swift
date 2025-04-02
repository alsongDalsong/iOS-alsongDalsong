import Accelerate
import AVFoundation

public class ASAudioVisualizer {
    private enum PlayState {
        case play, pause, stop
    }
    
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()

    private var sampleCount = 20
    private var audioFile: AVAudioFile?
    private var playState: PlayState = .stop
    
    public var fftMagnitudes: [Float] = []
    public var progress: Double {
        guard let nodetime = player.lastRenderTime,
              let playerTime = player.playerTime(forNodeTime: nodetime),
              let audioFile else { return 0.0 }
        
        let duration = Double(audioFile.length) / audioFile.processingFormat.sampleRate
        
        return min(1.0, Double(playerTime.sampleTime) / playerTime.sampleRate / duration)
    }
    
    public init() { }
    
    public func bind(data: Data, count: Int = 20) {
        sampleCount = count

        _ = engine.mainMixerNode

        engine.prepare()
        try? engine.start()

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        try? data.write(to: tempURL)

        guard let file = try? AVAudioFile(forReading: tempURL) else { return }
        audioFile = file  // 파일 저장 (재생을 다시 시작할 때 사용)

        let format = file.processingFormat

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        installFFT()
    }

    public func play() {
        guard let file = audioFile else { return }

        if playState == .stop {
            player.scheduleFile(file, at: nil) { [weak self] in
                self?.playState = .stop
            }
        }
        
        player.play()
        playState = .play
    }
    
    public func pause() {
        guard playState == .play else { return }
        
        player.pause()
        playState = .pause
    }

    public func stop() {
        guard playState == .play else { return }

        player.stop()
        playState = .stop
    }

    private func installFFT() {
        guard let fftSetup = vDSP_DFT_zop_CreateSetup(
            nil,
            UInt(1024),
            vDSP_DFT_Direction.FORWARD
        ) else { return }

        engine.mainMixerNode.installTap(
            onBus: 0,
            bufferSize: UInt32(1024),
            format: nil
        ) { [self] buffer, _ in
            guard let channelData = buffer.floatChannelData?[0] else { return }
            fftMagnitudes = fft(data: channelData, setup: fftSetup)
        }
    }
}

extension ASAudioVisualizer {
    private func fft(data: UnsafeMutablePointer<Float>, setup: OpaquePointer) -> [Float] {
        var realIn = [Float](repeating: 0, count: 1024)
        var imagIn = [Float](repeating: 0, count: 1024)
        var realOut = [Float](repeating: 0, count: 1024)
        var imagOut = [Float](repeating: 0, count: 1024)
            
        for i in 0..<1024 {
            realIn[i] = data[i]
        }
        
        vDSP_DFT_Execute(setup, &realIn, &imagIn, &realOut, &imagOut)
        
        var magnitudes = [Float](repeating: 0, count: sampleCount)
        
        realOut.withUnsafeMutableBufferPointer { realBP in
            imagOut.withUnsafeMutableBufferPointer { imagBP in
                guard let realBPAddress = realBP.baseAddress, let imagBPAddress = imagBP.baseAddress else { return }
                var complex = DSPSplitComplex(realp: realBPAddress, imagp: imagBPAddress)
                vDSP_zvabs(&complex, 1, &magnitudes, 1, UInt(sampleCount))
            }
        }
        
        var normalizedMagnitudes = [Float](repeating: 0.0, count: sampleCount)
        var scalingFactor = Float(1)
        vDSP_vsmul(&magnitudes, 1, &scalingFactor, &normalizedMagnitudes, 1, UInt(sampleCount))
            
        return normalizedMagnitudes
    }
}
