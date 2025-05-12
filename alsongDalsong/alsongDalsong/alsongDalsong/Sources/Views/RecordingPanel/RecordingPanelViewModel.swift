import Combine
import Foundation

final class RecordingPanelViewModel: @unchecked Sendable {
    private let sampleCount: Int = 24
    @Published var recordedData: Data?
    @Published private(set) var recorderAmplitude: Float = 0.0
    @Published private(set) var buttonState: AudioButtonState = .idle
    @Published private(set) var playIndex: Int?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        bindAudioHelper()
    }
    
    func configureAudioHelper() {
        GameAudioHelper.shared
            .isConcurrent(false)
    }
    
    @MainActor
    func startRecording() {
        Task {
            if buttonState == .recording { return }
            if buttonState == .playing { stopPlaying() }
            await GameAudioHelper.shared.startRecording()
        }
    }
    
    private func updateButtonState(_ state: AudioButtonState) {
        buttonState = state
    }
    
    @MainActor
    func togglePlayPause() {
        guard recordedData != nil else { return }
        
        Task { [weak self] in
            self?.configureAudioHelper()
            
            if self?.buttonState == .playing {
                await GameAudioHelper.shared.stopPlaying()
                return
            }
            if self?.buttonState == .idle {
                await GameAudioHelper.shared.startPlaying(self?.recordedData, sourceType: .recorded, option: .full, needsWaveUpdate: true)
                return
            }
        }
    }
    
    @MainActor
    private func stopPlaying() {
        Task {
            await GameAudioHelper.shared.stopPlaying()
        }
    }
    
    private func bindAudioHelper() {
        GameAudioHelper.shared.amplitudePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$recorderAmplitude)
        
        GameAudioHelper.shared.playerStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] source, isPlaying in
                if source == .recorded {
                    self?.updateButtonState(isPlaying ? .playing : .idle)
                    return
                }
                if isPlaying {
                    self?.updateButtonState(.idle)
                    return
                }
            }
            .store(in: &self.cancellables)
        
        GameAudioHelper.shared.waveformUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] index in
                guard let self else { return }
                if index > self.sampleCount - 1 || index < 0 { return }
                self.playIndex = index
            }
            .store(in: &self.cancellables)
        
        GameAudioHelper.shared.recorderStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRecording in
                self?.updateButtonState(isRecording ? .recording : .idle)
            }
            .store(in: &self.cancellables)
        
        GameAudioHelper.shared.recorderDataPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.recordedData = data
            }
            .store(in: &self.cancellables)
    }
}
