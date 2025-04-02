import ASAudioKit
import ASEntity
import Combine
import UIKit

final class ASPlayPanelViewController: UIViewController {
    private let viewModel = ASPlayPanelViewModel()
    private let playPanel = ASPlayPanel(type: .large)
    
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        viewModel.bindVisualizer()
        
        view.addSubview(playPanel)
        
        playPanel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            playPanel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            playPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            playPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        playPanel.configure(by: viewModel.music)
        playPanel.onPlayButtonTapped = viewModel.togglePlay
        
        bind()
    }
    
    private func bind() {
        viewModel.$buttonState
            .sink { [weak self] state in
                self?.playPanel.configure(with: state)
            }
            .store(in: &cancellables)
        
        viewModel.$progress
            .sink { [weak self] progress in
                self?.playPanel.configure(progress: progress, magnitudes: self?.viewModel.fftMagnitudes ?? [])
            }
            .store(in: &cancellables)
        
        viewModel.$fftMagnitudes
            .sink { [weak self] magnitudes in
                self?.playPanel.configure(progress: self?.viewModel.progress ?? 0, magnitudes: magnitudes)
            }
            .store(in: &cancellables)
    }
}

final class ASPlayPanelViewModel {
    @Published var music: Music? = Music(id: "1422639704", title: "D (Half Moon) [feat. Gaeko]", artist: "DEAN", artworkUrl: URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/8e/a2/d0/8ea2d001-0b52-a451-4a7c-de35d3502155/00602547860828.rgb.jpg/300x300bb.jpg"), previewUrl: URL(string: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview115/v4/98/4f/8e/984f8e93-2901-c8b3-5883-8281b363f723/mzaf_11734879238275302685.plus.aac.p.m4a")!, artworkBackgroundColor: "#7A3B68")
    @Published var preview: Data?
    @Published var buttonState: ASPlayButtonState = .play
    
    private let visualizer = ASAudioVisualizer()
    private var isPlaying = false
    private var timer: Timer?
    
    @Published var progress: Double = 0.0
    @Published var fftMagnitudes: [Float] = [0, 0, 0, 0, 0, 0]
    
    @MainActor
    func bindVisualizer() {
        Task {
            guard let music, let url = music.previewUrl else { return }
            let (data, _) = try await URLSession.shared.data(from: url)
            visualizer.bind(data: data, count: 6)
        }
    }
    
    @MainActor
    func getArtwork() {
        Task {
            guard let music, let url = music.previewUrl else { return }
            let (data, _) = try await URLSession.shared.data(from: url)
            preview = data
        }
    }
    
    @MainActor
    func togglePlay() {
        if isPlaying {
            progress = 0.0
            fftMagnitudes = [0, 0, 0, 0, 0, 0]
            visualizer.stop()
            timer?.invalidate()
            buttonState = .play
        } else {
            visualizer.play()
            startUpdatingVisualizer()
            buttonState = .stop
        }
        isPlaying.toggle()
    }
    
    @MainActor
    private func startUpdatingVisualizer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.progress = self?.visualizer.progress ?? 0.0
            self?.fftMagnitudes = self?.visualizer.fftMagnitudes ?? []
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    ASPlayPanelViewController()
}
