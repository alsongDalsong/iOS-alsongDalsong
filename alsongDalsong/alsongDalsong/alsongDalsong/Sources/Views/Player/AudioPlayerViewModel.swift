import ASAudioKit
import ASEntity
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

    init(
        music: Music?,
        dataDownloadRepository: DataDownloadRepositoryProtocol
    ) {
        self.music = music
        self.dataDownloadRepository = dataDownloadRepository
        getPreviewData()
        getArtworkData()
        bindAudioHelper()
    }

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
            isPlaying = false
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
                if self.isPlaying, !state {
                    self.unbindAudioHelper()
                }

                self.isPlaying = state
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
