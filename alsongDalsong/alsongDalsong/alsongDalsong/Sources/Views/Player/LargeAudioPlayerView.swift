import ASContainer
import ASEntity
import ASRepositoryProtocol
import Combine
import UIKit

enum AudioControlButtonState {
    case play, stop
    
    var symbol: UIImage? {
        switch self {
        case .play: UIImage(systemName: "play.fill")
        case .stop: UIImage(systemName: "stop.fill")
        }
    }
}

final class LargeAudioPlayerView: UIView {
    private let coverImageView = UIImageView()
    private let blurView = UIVisualEffectView()
    private let backgroundView = UIView()
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    private let controlButton = UIButton()
    private let playProgressView = PlayProgressView()
    private let frequencyWaveView = FrequencyWaveView()
    private let stackView = UIStackView()

    private var cancellables = Set<AnyCancellable>()
    private var viewModel: AudioPlayerViewModel? = nil

    var controlButtonDidTapped: (() -> Void)?
    
    init() {
        super.init(frame: .zero)
        setupView()
        setupStyle()
        setupLayout()
        setupAction()
        bindWithPlayer()
    }

    func bind(to dataSource: Published<Music?>.Publisher) {
        dataSource
            .receive(on: DispatchQueue.main)
            .sink { [weak self] music in
                guard let self else { return }

                if music == nil {
                    self.configure(with: .stop)
                    self.configure(title: nil, artist: nil)
                    self.configure(imageData: nil)
                    return
                }

                let dataDownloadRepository = DIContainer.shared.resolve(DataDownloadRepositoryProtocol.self)
                self.viewModel = AudioPlayerViewModel(
                    music: music,
                    dataDownloadRepository: dataDownloadRepository
                )
                self.bindViewModel()
                self.configure(title: music?.title, artist: music?.artist)
            }
            .store(in: &cancellables)
    }

    func bind(to dataSource: Published<Bool>.Publisher) {
        dataSource
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let isPlaying = self?.viewModel?.isPlaying else { return }

                if state, isPlaying {
                    self?.viewModel?.togglePlay()
                }
            }
            .store(in: &cancellables)
    }

    private func bindWithPlayer() {
        controlButtonDidTapped = { [weak self] in
            self?.viewModel?.togglePlay()
        }
    }

    private func bindViewModel() {
        viewModel?.$buttonState
            .sink { [weak self] state in
                self?.configure(with: state)
            }
            .store(in: &cancellables)

        viewModel?.$artwork
            .receive(on: DispatchQueue.main)
            .sink { [weak self] artwork in
                self?.configure(imageData: artwork)
            }
            .store(in: &cancellables)

        viewModel?.$audioProgress
            .sink { [weak self] progress in
                self?.configure(
                    progress: progress,
                    normalizedFrequencyAmplitudes: self?.viewModel?.normalizedFrequencyAmplitudes ?? []
                )
            }
            .store(in: &cancellables)

        viewModel?.$normalizedFrequencyAmplitudes
            .sink { [weak self] normalizedFrequencyAmplitudes in
                self?.configure(
                    progress: self?.viewModel?.audioProgress ?? 0,
                    normalizedFrequencyAmplitudes: normalizedFrequencyAmplitudes
                )
            }
            .store(in: &cancellables)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupView() {
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(artistLabel)
        
        addSubview(coverImageView)
        addSubview(blurView)
        addSubview(backgroundView)
        addSubview(stackView)
        addSubview(controlButton)
        addSubview(frequencyWaveView)
        addSubview(playProgressView)
    }
    
    func setupStyle() {
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.layer.cornerRadius = .responsiveWidth(12)
        coverImageView.clipsToBounds = true
        
        blurView.effect = UIBlurEffect(style: .systemMaterial)
        blurView.layer.cornerRadius = .responsiveWidth(12)
        blurView.clipsToBounds = true
        
        backgroundView.layer.cornerRadius = .responsiveWidth(20)
        backgroundView.layer.cornerCurve = .continuous
        backgroundView.backgroundColor = .systemGroupedBackground
        backgroundView.layer.shadowColor = UIColor.gray.cgColor
        backgroundView.layer.shadowOpacity = 0.5
        backgroundView.layer.shadowOffset = CGSize(width: .responsiveWidth(0), height: .responsiveHeight(4))
        backgroundView.layer.shadowRadius = .responsiveWidth(2)

        titleLabel.textColor = .label
        titleLabel.font = .systemFont(ofSize: .responsiveHeight(20))

        artistLabel.textColor = .secondaryLabel
        artistLabel.font = .systemFont(ofSize: .responsiveHeight(18))

        var buttonConfiguration = UIButton.Configuration.borderless()
        let imageConfiguration = UIImage.SymbolConfiguration(pointSize: .responsiveWidth(32))
        buttonConfiguration.preferredSymbolConfigurationForImage = imageConfiguration
        buttonConfiguration.baseForegroundColor = .asForeground
        buttonConfiguration.image = UIImage(systemName: "play.fill")
        
        if #available(iOS 17.0, *) { controlButton.isSymbolAnimationEnabled = true }
        controlButton.configuration = buttonConfiguration
        
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = .responsiveHeight(4)
    }
    
    func setupLayout() {
        coverImageView.translatesAutoresizingMaskIntoConstraints = false
        blurView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        playProgressView.translatesAutoresizingMaskIntoConstraints = false
        controlButton.translatesAutoresizingMaskIntoConstraints = false
        frequencyWaveView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            coverImageView.topAnchor.constraint(equalTo: topAnchor),
            coverImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .responsiveWidth(20)),
            coverImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: .responsiveWidth(-20)),
            coverImageView.heightAnchor.constraint(equalTo: coverImageView.widthAnchor),
            
            blurView.topAnchor.constraint(equalTo: coverImageView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: coverImageView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: coverImageView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: coverImageView.bottomAnchor),
            
            backgroundView.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: .responsiveHeight(20)),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: .responsiveHeight(-20)),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),

            stackView.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: .responsiveHeight(8)),
            stackView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: .responsiveWidth(12)),
            stackView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: .responsiveWidth(-12)),

            playProgressView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: .responsiveHeight(8)),
            playProgressView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            playProgressView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            playProgressView.heightAnchor.constraint(equalToConstant: .responsiveHeight(8)),

            controlButton.topAnchor.constraint(equalTo: playProgressView.bottomAnchor, constant: .responsiveHeight(8)),
            controlButton.centerXAnchor.constraint(equalTo: playProgressView.centerXAnchor),
            controlButton.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: .responsiveHeight(-8)),

            frequencyWaveView.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: .responsiveHeight(18)),
            frequencyWaveView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: .responsiveWidth(-18)),
            frequencyWaveView.widthAnchor.constraint(equalToConstant: .responsiveWidth(20)),
            frequencyWaveView.heightAnchor.constraint(equalToConstant: .responsiveHeight(14))
        ])
    }
    
    func setupAction() {
        controlButton.addAction(UIAction { [weak self] _ in
            self?.controlButtonDidTapped?()
        }, for: .touchUpInside)
    }
}

// MARK: - Configure Methods

extension LargeAudioPlayerView {
    func configure(title: String?, artist: String?) {
        titleLabel.text = title ?? "???"
        artistLabel.text = artist ?? "???"
        
        blurView.alpha = title == nil ? 1 : 0
    }

    func configure(imageData: Data?) {
        if let data = imageData, let image = UIImage(data: data) {
            coverImageView.image = image
            coverImageView.backgroundColor = .clear
        } else {
            coverImageView.image = nil
            coverImageView.backgroundColor = .systemGray4
        }
    }

    func configure(progress: Double, normalizedFrequencyAmplitudes: [Float]) {
        let progress = CGFloat(progress)
        
        UIView.animate(withDuration: 0.3) {
            self.playProgressView.progress = progress
        }
        
        frequencyWaveView.normalizedFrequencyAmplitudes = normalizedFrequencyAmplitudes
    }
    
    func configure(with buttonState: AudioControlButtonState) {
        UIView.animate(withDuration: 0.1, animations: {
            self.controlButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }, completion: { _ in
            UIView.animate(withDuration: 0.2, animations: {
                self.controlButton.transform = .identity
                self.controlButton.configuration?.image = buttonState.symbol
            })
        })
    }
}
