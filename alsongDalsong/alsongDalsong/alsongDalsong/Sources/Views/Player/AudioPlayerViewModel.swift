import ASAudioKit
import ASEntity
import ASRepositoryProtocol
import Combine
import Foundation

final class AudioPlayerViewModel: @unchecked Sendable {
    @Published var artworkData: Data?

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
    }
    
    init(
        previewData: Data?,
        artworkData: Data?
    ) {
        self.previewData = previewData
        self.artworkData = artworkData
    }

    deinit {
        AudioHelper.shared.stopEngine()
    }

    @MainActor
    func togglePlay() {
        if AudioHelper.shared.isEnginePlaying {
            AudioHelper.shared.stopEngine()
        } else {
            guard let previewData else { return }
            AudioHelper.shared.playEngine(previewData)
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
}
