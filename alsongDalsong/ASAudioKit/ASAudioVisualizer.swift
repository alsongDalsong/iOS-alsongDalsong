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
    
    public var normalizedFrequencyAmplitudes: [Float] = []
    public var progress: Double {
        guard let nodetime = player.lastRenderTime,
              let playerTime = player.playerTime(forNodeTime: nodetime),
              let audioFile else { return 0.0 }
        
        let duration = Double(audioFile.length) / audioFile.processingFormat.sampleRate
        
        return min(1.0, Double(playerTime.sampleTime) / playerTime.sampleRate / duration)
    }
    
    public init() { }
    
    public func bind(data: Data, sampleCount: Int = 6) {
        self.sampleCount = sampleCount

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

        installFastFourierTransform()
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

    private func installFastFourierTransform() {
        let length = UInt(1024)
        let bufferSize = UInt32(1024)
        let direction = vDSP_DFT_Direction.FORWARD
        
        guard let setup = vDSP_DFT_zop_CreateSetup(nil, length, direction) else { return }

        engine.mainMixerNode.installTap(onBus: 0, bufferSize: bufferSize, format: nil) { buffer, _ in
            guard let channelData = buffer.floatChannelData?[0] else { return }
            self.normalizedFrequencyAmplitudes = self.fastFourierTransform(data: channelData, setup: setup)
        }
    }
}

extension ASAudioVisualizer {
    private func fastFourierTransform(data: UnsafeMutablePointer<Float>, setup: OpaquePointer) -> [Float] {
        var realIn = [Float](repeating: 0, count: 1024)
        var imagIn = [Float](repeating: 0, count: 1024)
        var realOut = [Float](repeating: 0, count: 1024)
        var imagOut = [Float](repeating: 0, count: 1024)
            
        for i in 0..<1024 {
            realIn[i] = data[i]
        }
        
        /// Fast Fourier Transform 실행 (입력: realIn, imagIn / 출력: realOut, imagOut)
        vDSP_DFT_Execute(setup, &realIn, &imagIn, &realOut, &imagOut)
        
        var frequencyMagnitude = [Float](repeating: 0, count: sampleCount)
        
        /// FFT 결과에서 실수(real)와 허수(imaginary)를 결합하여 진폭 계산
        realOut.withUnsafeMutableBufferPointer { realBP in
            imagOut.withUnsafeMutableBufferPointer { imagBP in
                guard let realBPAddress = realBP.baseAddress, let imagBPAddress = imagBP.baseAddress else { return }
                
                // 복소수 크기 계산 (√(real² + imag²))
                var complex = DSPSplitComplex(realp: realBPAddress, imagp: imagBPAddress)
                vDSP_zvabs(&complex, 1, &frequencyMagnitude, 1, UInt(sampleCount))
            }
        }
        
        /// 크기 정규화 0 ~ 1 의 값으로 만듬
        var normalizedFrequencyAmplitudes = [Float](repeating: 0.0, count: sampleCount)
        let maxAmplitude = frequencyMagnitude.max() ?? 1
        var scalingFactor = 1 / maxAmplitude
        vDSP_vsmul(&frequencyMagnitude, 1, &scalingFactor, &normalizedFrequencyAmplitudes, 1, UInt(sampleCount))
            
        return normalizedFrequencyAmplitudes
    }
}
