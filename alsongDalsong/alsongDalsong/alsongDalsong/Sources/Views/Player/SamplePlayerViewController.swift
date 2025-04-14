import ASAudioKit
import ASEntity
import Combine
import UIKit

final class SamplePlayerViewController: UIViewController {
    private let viewModel = SamplePlayerViewModel()
    private let largePlayerView = LargeAudioPlayerView()
    private let mediumSubmitPlayerView = MediumAudioPlayerView(type: .submit)
    private let mediumResultPlayerView = MediumAudioPlayerView(type: .result)
    private let mediumResultPlayerView2 = MediumAudioPlayerView(type: .result)
    
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        viewModel.bindVisualizer()
        
        view.addSubview(largePlayerView)
        view.addSubview(mediumSubmitPlayerView)
        view.addSubview(mediumResultPlayerView)
        view.addSubview(mediumResultPlayerView2)
        
        largePlayerView.translatesAutoresizingMaskIntoConstraints = false
        mediumSubmitPlayerView.translatesAutoresizingMaskIntoConstraints = false
        mediumResultPlayerView.translatesAutoresizingMaskIntoConstraints = false
        mediumResultPlayerView2.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            largePlayerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            largePlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            largePlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            mediumSubmitPlayerView.topAnchor.constraint(equalTo: largePlayerView.bottomAnchor, constant: 12),
            mediumSubmitPlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            mediumSubmitPlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            mediumResultPlayerView.topAnchor.constraint(equalTo: mediumSubmitPlayerView.bottomAnchor, constant: 12),
            mediumResultPlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            mediumResultPlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            mediumResultPlayerView2.topAnchor.constraint(equalTo: mediumResultPlayerView.bottomAnchor, constant: 12),
            mediumResultPlayerView2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            mediumResultPlayerView2.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -120)
        ])
        
        if let music = viewModel.music, let title = music.title, let artist = music.artist {
            largePlayerView.configure(title: title, artist: artist, imageData: viewModel.coverImageData)
            largePlayerView.controlButtonDidTapped = viewModel.togglePlay
                        
            mediumSubmitPlayerView.configure(title: title, artist: artist, imageData: viewModel.coverImageData)
            mediumSubmitPlayerView.controlButtonDidTapped = viewModel.togglePlay
            
            mediumResultPlayerView.configure(title: title, artist: artist, imageData: viewModel.coverImageData)
            mediumResultPlayerView2.configure(title: title, artist: artist, imageData: viewModel.coverImageData)
        }
        
        bind()
    }
    
    private func bind() {
        viewModel.$buttonState
            .sink { [weak self] state in
                self?.largePlayerView.configure(with: state)
                self?.mediumSubmitPlayerView.configure(with: state)
            }
            .store(in: &cancellables)
        
        viewModel.$audioProgress
            .sink { [weak self] progress in
                self?.largePlayerView.configure(
                    progress: progress,
                    normalizedFrequencyAmplitudes: self?.viewModel.normalizedFrequencyAmplitudes ?? []
                )
            }
            .store(in: &cancellables)
        
        viewModel.$normalizedFrequencyAmplitudes
            .sink { [weak self] normalizedFrequencyAmplitudes in
                self?.largePlayerView.configure(
                    progress: self?.viewModel.audioProgress ?? 0,
                    normalizedFrequencyAmplitudes: normalizedFrequencyAmplitudes
                )
                
                self?.mediumResultPlayerView.configure(
                    normalizedFrequencyAmplitudes: normalizedFrequencyAmplitudes
                )
                
                self?.mediumResultPlayerView2.configure(
                    normalizedFrequencyAmplitudes: normalizedFrequencyAmplitudes
                )
            }
            .store(in: &cancellables)
    }
}

final class SamplePlayerViewModel: @unchecked Sendable {
    @Published var music: Music? = Music(id: "1422639704", title: "D (Half Moon) [feat. Gaeko]", artist: "DEAN", artworkUrl: URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/8e/a2/d0/8ea2d001-0b52-a451-4a7c-de35d3502155/00602547860828.rgb.jpg/300x300bb.jpg"), previewUrl: URL(string: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview115/v4/98/4f/8e/984f8e93-2901-c8b3-5883-8281b363f723/mzaf_11734879238275302685.plus.aac.p.m4a")!, artworkBackgroundColor: "#7A3B68")
    @Published var coverImageData: Data?
    
    private let playerEngine = ASAudioPlayerEngine()
    private var isPlaying = false
    private var timer: Timer?
    
    @Published var buttonState: AudioControlButtonState = .play
    @Published var audioProgress: Double = 0.0
    @Published var normalizedFrequencyAmplitudes: [Float] = [0, 0, 0, 0, 0, 0]
    
    init() {
        getArtworkData()
    }
    
    deinit {
        playerEngine.stop()
        timer?.invalidate()
    }
    
    @MainActor
    func bindVisualizer() {
        Task {
            guard let music, let url = music.previewUrl else { return }
            let (data, _) = try await URLSession.shared.data(from: url)
            playerEngine.bind(data: data)
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
    
    private func getArtworkData() {
        guard let url = music?.artworkUrl else { return }
        Task {
            coverImageData = try await URLSession.shared.data(from: url).0
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    SamplePlayerViewController()
}
