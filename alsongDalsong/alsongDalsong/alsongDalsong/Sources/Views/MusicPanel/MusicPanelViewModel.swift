import ASEntity
import ASRepositoryProtocol
import Combine
import Foundation

final class MusicPanelViewModel: @unchecked Sendable {
    @Published var type: MusicPanelType
    @Published var music: Music?
    @Published var artwork: Data?
    @Published var preview: Data?
    @Published private(set) var buttonState: AudioButtonState = .idle
    private let dataDownloadRepository: DataDownloadRepositoryProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        music: Music?,
        type: MusicPanelType = .large,
        dataDownloadRepository: DataDownloadRepositoryProtocol
    ) {
        self.music = music
        self.type = type
        self.dataDownloadRepository = dataDownloadRepository
        getPreviewData()
        getArtworkData()
        bindAudioHelper()
    }
    
    deinit {
        Task {
            await AudioHelper.shared.stopPlaying()
        }
    }
    
    private func bindAudioHelper() {
        AudioHelper.shared.playerStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] source, isPlaying in
                switch source {
                case let .imported(panelType):
                    self?.updateButtonState(type: panelType, isPlaying ? .playing : .idle)
                default: if isPlaying {
                    self?.updateButtonState(type: .compact, .idle)
                    self?.updateButtonState(type: .large, .idle)
                }
                }
            }
            .store(in: &cancellables)
        
        AudioHelper.shared.recorderStatePublisher
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRecording in
                self?.updateButtonState(type: .compact, .idle)
                self?.updateButtonState(type: .large, .idle)
            }
            .store(in: &cancellables)
    }
    
    func configureAudioHelper() {
        AudioHelper.shared
            .isConcurrent(false)
    }
    
    @MainActor
    func togglePlayPause(_ type: MusicPanelType) {
        Task { [weak self] in
            guard let self = self else { return }
            
            configureAudioHelper()
            
            switch buttonState {
            case .playing:
                AudioHelper.shared.stopEngine()
                
            case .idle:
                AudioHelper.shared.playEngine(preview)
                
            default: break
            }
        }
    }
    
    private func updateButtonState(type: MusicPanelType, _ state: AudioButtonState) {
        if self.type == type {
            buttonState = state
        }
    }
    
    private func getPreviewData() {
        guard let previewUrl = music?.previewUrl else { return }
        Task { @MainActor in
            preview = await dataDownloadRepository.downloadData(url: previewUrl)
        }
    }
    
    private func getArtworkData() {
        guard let artworkUrl = music?.artworkUrl else { return }
        Task { @MainActor in
            artwork = await dataDownloadRepository.downloadData(url: artworkUrl)
        }
    }
}
