import Combine
import UIKit

final class RecordingPanel: UIView {
    private let playButton = UIButton()
    private let waveFormView = WaveForm()
    private let viewModel = RecordingPanelViewModel()
    private var cancellables = Set<AnyCancellable>()
    var onRecordingFinished: ((Data) -> Void)?

    init() {
        super.init(frame: .zero)
        setupButton()
        setupUI()
        setupLayout()
        bindViewModel()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupLayout()
        setupButton()
    }

    func bind(
        to dataSource: Published<Bool>.Publisher
    ) {
        dataSource
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reset()
                self?.viewModel.startRecording()
            }
            .store(in: &cancellables)
    }

    private func bindViewModel() {
        viewModel.$recordedData
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] recordedData in
                self?.onRecordingFinished?(recordedData)
            }
            .store(in: &cancellables)
        viewModel.$recorderAmplitude
            .receive(on: DispatchQueue.main)
            .sink { [weak self] amplitude in
                self?.updateWaveForm(amplitude: CGFloat(amplitude))
            }
            .store(in: &cancellables)
        viewModel.$buttonState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateButtonImage(with: state)
                self?.updateWaveForm(state: state)
            }
            .store(in: &cancellables)
        viewModel.$playIndex
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] index in
                self?.updateWaveForm(index: index)
            }
            .store(in: &cancellables)
    }

    private func updateButtonImage(with state: AudioButtonState) {
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: [.curveEaseOut],
            animations: { [weak self] in
                self?.playButton.transform = .identity
            }, completion: { [weak self] _ in
                self?.playButton.configuration?.baseForegroundColor = state.color
                self?.playButton.configuration?.image = state.symbol
            }
        )
    }

    private func setupButton() {
        var buttonConfiguration = UIButton.Configuration.borderless()
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        buttonConfiguration.image = viewModel.buttonState.symbol
        buttonConfiguration.preferredSymbolConfigurationForImage = imageConfig
        buttonConfiguration.baseForegroundColor = .asForeground
        buttonConfiguration.contentInsets = .zero
        buttonConfiguration.background.backgroundColorTransformer = UIConfigurationColorTransformer { color in
            color.withAlphaComponent(0.0)
        }

        playButton.configurationUpdateHandler = { button in
            UIView.animate(
                withDuration: 0.15,
                delay: 0,
                usingSpringWithDamping: 0.5,
                initialSpringVelocity: 0.5,
                options: [.allowUserInteraction],
                animations: {
                    if button.isHighlighted {
                        button.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                    } else {
                        button.transform = .identity
                    }
                }
            )
        }

        playButton.configuration = buttonConfiguration
        playButton.addAction(UIAction { [weak self] _ in
            self?.didButtonTapped()
        }, for: .touchUpInside)
    }

    private func didButtonTapped() {
        viewModel.togglePlayPause()
    }

    private func setupUI() {
        layer.borderWidth = 3
        layer.borderColor = UIColor.profileViewCircle.cgColor
        layer.backgroundColor = UIColor.asSystem.cgColor
        layer.cornerRadius = 12
        
        layer.shadowColor = UIColor.asShadow.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 2
        
        addSubview(playButton)
        addSubview(waveFormView)
    }

    private func setupLayout() {
        playButton.translatesAutoresizingMaskIntoConstraints = false
        waveFormView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playButton.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            playButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            playButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            playButton.widthAnchor.constraint(equalToConstant: 32),

            waveFormView.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 8),
            waveFormView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            waveFormView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            waveFormView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
        ])
    }

    private func updateWaveForm(amplitude: CGFloat) {
        waveFormView.updateAmplitude(with: amplitude)
    }

    private func updateWaveForm(index: Int) {
        waveFormView.updatePlayingIndex(index)
    }

    private func updateWaveForm(state: AudioButtonState) {
        if state == .idle { waveFormView.resetColor() }
    }

    private func reset() {
        waveFormView.resetView()
    }
}
