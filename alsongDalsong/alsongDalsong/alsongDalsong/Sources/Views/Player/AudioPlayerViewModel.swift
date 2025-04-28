import ASAudioKit
import ASEntity
import ASRepositoryProtocol
import Combine
import Foundation

final class AudioPlayerViewModel: @unchecked Sendable {
    @Published var music: Music?
    @Published var artwork: Data?
    @Published var buttonState: AudioControlButtonState = .play
    @Published var audioProgress: Double = 0.0
    @Published var normalizedFrequencyAmplitudes: [Float] = [0, 0, 0, 0, 0, 0]

    private let dataDownloadRepository: DataDownloadRepositoryProtocol
    private let playerEngine = ASAudioPlayerEngine()
    private(set) var isPlaying: Bool = false
    private var timer: Timer?

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

    deinit {
        playerEngine.stop()
        timer?.invalidate()
    }

    @MainActor
    func togglePlay() {
        if isPlaying {
            audioProgress = 0.0
            normalizedFrequencyAmplitudes = [0, 0, 0, 0, 0, 0]

            playerEngine.stop()
            timer?.invalidate()
            buttonState = .play
        } else {
            playerEngine.play()
            updateAudioProgressAndNormalizedFrequencyAmplitudes()
            buttonState = .stop
        }

        isPlaying.toggle()
    }

    private func updateButtonState(_ state: AudioControlButtonState) {
        buttonState = state
    }

    private func getPreviewData() {
        guard let previewUrl = music?.previewUrl else { return }
        Task { @MainActor in
            guard let preview = await dataDownloadRepository.downloadData(url: previewUrl) else { return }
            playerEngine.bind(data: preview)
        }
    }

    private func getArtworkData() {
        guard let artworkUrl = music?.artworkUrl else { return }
        Task { @MainActor in
            artwork = await dataDownloadRepository.downloadData(url: artworkUrl)
        }
    }

    @MainActor
    private func updateAudioProgressAndNormalizedFrequencyAmplitudes() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.audioProgress = self?.playerEngine.audioProgress ?? 0.0
                self?.normalizedFrequencyAmplitudes = self?.playerEngine.normalizedFrequencyAmplitudes ?? []

                if self?.audioProgress == 1 {
                    self?.audioProgress = 0.0
                    self?.normalizedFrequencyAmplitudes = [0, 0, 0, 0, 0, 0]

                    self?.buttonState = .play
                    self?.isPlaying = false
                    self?.timer?.invalidate()
                }
            }
        }
    }
}
