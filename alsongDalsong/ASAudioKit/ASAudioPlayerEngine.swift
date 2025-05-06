import Accelerate
import AVFoundation

public class ASAudioPlayerEngine: @unchecked Sendable {
    private enum PlayState {
        case play, pause, stop
    }
    
    private let audioEngine = AVAudioEngine()
    private let audioPlayer = AVAudioPlayerNode()

    private var volume: Float = 1.0
    
    private var sampleCount = 6
    private var audioFile: AVAudioFile?
    private var playState: PlayState = .stop
    private var _normalizedFrequencyAmplitudes: [Float] = []
    
    private let syncQueue = DispatchQueue(label: "audioVisualizer.syncQueue")
    
    public var normalizedFrequencyAmplitudes: [Float] {
        get {
            syncQueue.sync {
                _normalizedFrequencyAmplitudes
            }
        }
        set {
            syncQueue.async(flags: .barrier) { [weak self] in
                self?._normalizedFrequencyAmplitudes = newValue
            }
        }
    }
    
    public func changeVolume(_ volume: Float) {
        self.volume = volume
        audioPlayer.volume = volume
    }
    
    public var audioProgress: Double {
        guard let nodetime = audioPlayer.lastRenderTime,
              let playerTime = audioPlayer.playerTime(forNodeTime: nodetime),
              let audioFile else { return 0.0 }
        
        let duration = Double(audioFile.length) / audioFile.processingFormat.sampleRate
        
        return min(1.0, Double(playerTime.sampleTime) / playerTime.sampleRate / duration)
    }
    
    public init() {}
    
    public func bind(data: Data, sampleCount: Int = 6) {
        self.sampleCount = sampleCount

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [])
        try? session.setActive(true, options: .notifyOthersOnDeactivation)
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        try? data.write(to: tempURL)

        guard let file = try? AVAudioFile(forReading: tempURL) else { return }
        audioFile = file
        
        let format = file.processingFormat

        audioEngine.attach(audioPlayer)
        audioEngine.connect(audioPlayer, to: audioEngine.mainMixerNode, format: format)
        audioEngine.prepare()
        
        installFastFourierTransform()
    }

    public func play() {
        guard let file = audioFile else { return }
        audioPlayer.volume = volume
        if !audioEngine.isRunning {
            try? audioEngine.start()
        }

        if playState == .stop {
            audioPlayer.stop()
            audioPlayer.scheduleFile(file, at: nil) { [weak self] in
                self?.playState = .stop
            }
        }
        
        audioPlayer.play()
        playState = .play
    }
    
    public func pause() {
        guard playState == .play else { return }
        
        audioPlayer.pause()
        playState = .pause
    }

    public func stop() {
        guard playState == .play else { return }

        audioPlayer.stop()
        playState = .stop
    }

    private func installFastFourierTransform() {
        let length: UInt = 1024
        let bufferSize: UInt32 = 1024
        let direction = vDSP_DFT_Direction.FORWARD
        
        guard let setup = vDSP_DFT_zop_CreateSetup(nil, length, direction) else { return }

        let mainMixer = audioEngine.mainMixerNode
        mainMixer.removeTap(onBus: 0)
        
        mainMixer.installTap(onBus: 0, bufferSize: bufferSize, format: nil) { buffer, _ in
            guard let channelData = buffer.floatChannelData?[0] else { return }
            self.normalizedFrequencyAmplitudes = self.fastFourierTransform(data: channelData, setup: setup)
        }
    }
}

extension ASAudioPlayerEngine {
    private func fastFourierTransform(data: UnsafeMutablePointer<Float>, setup: OpaquePointer) -> [Float] {
        var realIn = [Float](repeating: 0, count: 1024)
        var imagIn = [Float](repeating: 0, count: 1024)
        var realOut = [Float](repeating: 0, count: 1024)
        var imagOut = [Float](repeating: 0, count: 1024)
            
        for i in 0 ..< 1024 {
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
