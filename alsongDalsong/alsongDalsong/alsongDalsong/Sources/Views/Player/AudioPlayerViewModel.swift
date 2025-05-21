import ASAudioKit
import ASEntity
import ASLogKit
import ASRepositoryProtocol
import Combine
import Foundation

final class AudioPlayerViewModel: @unchecked Sendable {
    @Published var artworkData: Data?
    @Published var progress: Double = 0
    @Published var normalizedFrequencyAmplitudes: [Float] = [0, 0, 0, 0, 0, 0]
    @Published var isPlaying = false

    private var music: Music?
    private var previewData: Data?
    private var dataDownloadRepository: DataDownloadRepositoryProtocol?

    private var cancellables = Set<AnyCancellable>()

    /// 플레이어 init
    init(
        music: Music?,
        dataDownloadRepository: DataDownloadRepositoryProtocol
    ) {
        self.music = music
        self.dataDownloadRepository = dataDownloadRepository
        getPreviewData()
        getArtworkData()
    }

    /// 결과화면 init
    init(
        previewData: Data?,
        artworkData: Data?
    ) {
        self.previewData = previewData
        self.artworkData = artworkData
        bindAudioHelper()
    }

    @MainActor
    func togglePlay() {
        if isPlaying {
            self.isPlaying = false
            GameAudioHelper.shared.stopEngine()
            unbindAudioHelper()
        } else {
            Task {
                await BgmAudioHelper.shared.stopPlaying()
            }
            guard let previewData else { return }

            bindAudioHelper()
            GameAudioHelper.shared.playEngine(previewData)
        }
    }

    private func getPreviewData() {
        guard let previewUrl = music?.previewUrl else { return }
        Task {
            previewData = await dataDownloadRepository?.downloadData(url: previewUrl)
        }
    }

    private func getArtworkData() {
        guard let artworkUrl = music?.artworkUrl else { return }
        Task {
            artworkData = await dataDownloadRepository?.downloadData(url: artworkUrl)
        }
    }

    private func bindAudioHelper() {
        Logger.debug("Bind AudioHelper")
        
        GameAudioHelper.shared.playerEnginePrgressPublisher
            .receive(on: DispatchQueue.main)
            .sink { self.progress = $0 }
            .store(in: &cancellables)

        GameAudioHelper.shared.normalizedFrequencyAmplitudesPublisher
            .receive(on: DispatchQueue.main)
            .sink { self.normalizedFrequencyAmplitudes = $0 }
            .store(in: &cancellables)

        GameAudioHelper.shared.engineStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { state in
                Logger.debug("Engine State: \(state) | isPlaying: \(self.isPlaying)")
                
                if self.isPlaying && !state {
                    Logger.debug("Unbind AudioHelper")
                    self.unbindAudioHelper()
                }

                self.isPlaying = state
                Logger.debug("isPlaying: \(self.isPlaying)")
            }
            .store(in: &cancellables)
    }

    private func unbindAudioHelper() {
        progress = 0
        normalizedFrequencyAmplitudes = [0, 0, 0, 0, 0, 0]
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
