import ASAudioKit
import ASEntity
import Combine
import UIKit

final class SamplePlayerViewController: UIViewController {
    private let viewModel = SamplePlayerViewModel()
    private let playerView = AudioPlayerView(type: .large)
    
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        viewModel.bindVisualizer()
        
        view.addSubview(playerView)
        
        playerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        playerView.configure(by: viewModel.music)
        playerView.onPlayButtonTapped = viewModel.togglePlay
        
        bind()
    }
    
    private func bind() {
        viewModel.$buttonState
            .sink { [weak self] state in
                self?.playerView.configure(with: state)
            }
            .store(in: &cancellables)
        
        viewModel.$audioProgress
            .sink { [weak self] progress in
                self?.playerView.configure(progress: progress, normalizedFrequencyAmplitudes: self?.viewModel.normalizedFrequencyAmplitudes ?? [])
            }
            .store(in: &cancellables)
        
        viewModel.$normalizedFrequencyAmplitudes
            .sink { [weak self] normalizedFrequencyAmplitudes in
                self?.playerView.configure(progress: self?.viewModel.audioProgress ?? 0, normalizedFrequencyAmplitudes: normalizedFrequencyAmplitudes)
            }
            .store(in: &cancellables)
    }
}

final class SamplePlayerViewModel {
    @Published var music: Music? = Music(id: "1422639704", title: "D (Half Moon) [feat. Gaeko]", artist: "DEAN", artworkUrl: URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/8e/a2/d0/8ea2d001-0b52-a451-4a7c-de35d3502155/00602547860828.rgb.jpg/300x300bb.jpg"), previewUrl: URL(string: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview115/v4/98/4f/8e/984f8e93-2901-c8b3-5883-8281b363f723/mzaf_11734879238275302685.plus.aac.p.m4a")!, artworkBackgroundColor: "#7A3B68")
    @Published var coverImageData: Data?
    @Published var buttonState: AudioControlButtonState = .play
    
    private let audioVisualizer = ASAudioVisualizer()
    private var isPlaying = false
    private var timer: Timer?
    
    @Published var audioProgress: Double = 0.0
    @Published var normalizedFrequencyAmplitudes: [Float] = [0, 0, 0, 0, 0, 0]
    
    @MainActor
    func bindVisualizer() {
        Task {
            guard let music, let url = music.previewUrl else { return }
            let (data, _) = try await URLSession.shared.data(from: url)
            audioVisualizer.bind(data: data)
        }
    }
    
    @MainActor
    func getArtwork() {
        Task {
            guard let music, let url = music.previewUrl else { return }
            let (data, _) = try await URLSession.shared.data(from: url)
            coverImageData = data
        }
    }
    
    @MainActor
    func togglePlay() {
        if isPlaying {
            audioProgress = 0.0
            normalizedFrequencyAmplitudes = [0, 0, 0, 0, 0, 0]
            
            audioVisualizer.stop()
            timer?.invalidate()
            buttonState = .play
        } else {
            audioVisualizer.play()
            updateAudioProgressAndNormalizedFrequencyAmplitudes()
            buttonState = .stop
        }
        
        isPlaying.toggle()
    }
    
    @MainActor
    private func updateAudioProgressAndNormalizedFrequencyAmplitudes() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.audioProgress = self?.audioVisualizer.audioProgress ?? 0.0
            self?.normalizedFrequencyAmplitudes = self?.audioVisualizer.normalizedFrequencyAmplitudes ?? []
            
            if self?.audioProgress == 1 {
                self?.audioProgress = 0.0
                self?.normalizedFrequencyAmplitudes = [0, 0, 0, 0, 0, 0]
                
                self?.buttonState = .play
                self?.isPlaying = false
            }
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    SamplePlayerViewController()
}
