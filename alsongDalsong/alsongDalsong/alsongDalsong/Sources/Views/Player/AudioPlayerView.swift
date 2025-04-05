import ASEntity
import UIKit

enum AudioPlayerType {
    case large, answer, result
}

enum AudioControlButtonState {
    case play, stop
    
    var symbol: UIImage? {
        switch self {
        case .play: UIImage(systemName: "play.fill")
        case .stop: UIImage(systemName: "stop.fill")
        }
    }
}

final class AudioPlayerView: UIView {
    private let coverImageView = UIImageView()
    private let blurView = UIVisualEffectView()
    private let backgroundView = UIView()
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    private let controlButton = UIButton()
    private let playProgressView = PlayProgressView()
    private let frequencyWaveView = FrequencyWaveView()
    private let stackView = UIStackView()
    
    private var audioPlayerType: AudioPlayerType = .large
    
    var onPlayButtonTapped: (() -> Void)?
    
    init(type: AudioPlayerType) {
        audioPlayerType = type
        super.init(frame: .zero)
        setupUI()
        setupStyle()
        setupLayout()
        setupAction()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupUI() {
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
        coverImageView.layer.cornerRadius = 12
        
        blurView.effect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        blurView.layer.cornerRadius = 12
        blurView.clipsToBounds = true
        blurView.alpha = 0.6
        
        backgroundView.layer.cornerRadius = 20
        backgroundView.layer.cornerCurve = .continuous
        backgroundView.backgroundColor = .systemGroupedBackground
        backgroundView.layer.shadowColor = UIColor.gray.cgColor
        backgroundView.layer.shadowOpacity = 0.5
        backgroundView.layer.shadowOffset = CGSize(width: 0, height: 4)
        backgroundView.layer.shadowRadius = 4
        
        titleLabel.textColor = .label
        titleLabel.font = .systemFont(ofSize: 20)
        
        artistLabel.textColor = .secondaryLabel
        artistLabel.font = .systemFont(ofSize: 18)
        
        var buttonConfiguration = UIButton.Configuration.borderless()
        let imageConfiguration = UIImage.SymbolConfiguration(pointSize: 32)
        buttonConfiguration.preferredSymbolConfigurationForImage = imageConfiguration
        buttonConfiguration.baseForegroundColor = .asBlack
        buttonConfiguration.image = UIImage(systemName: "play.fill")
        
        if #available(iOS 17.0, *) { controlButton.isSymbolAnimationEnabled = true }
        controlButton.configuration = buttonConfiguration
        
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 4
    }
    
    func setupAction() {
        controlButton.addAction(UIAction { [weak self] _ in
            self?.onPlayButtonTapped?()
        }, for: .touchUpInside)
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
            coverImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            coverImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            coverImageView.heightAnchor.constraint(equalTo: coverImageView.widthAnchor),
            
            blurView.topAnchor.constraint(equalTo: coverImageView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: coverImageView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: coverImageView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: coverImageView.bottomAnchor),
            
            backgroundView.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: 32),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            stackView.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -12),
            
            playProgressView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 12),
            playProgressView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            playProgressView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            playProgressView.heightAnchor.constraint(equalToConstant: 8),
            
            controlButton.topAnchor.constraint(equalTo: playProgressView.bottomAnchor, constant: 12),
            controlButton.centerXAnchor.constraint(equalTo: playProgressView.centerXAnchor),
            controlButton.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -12),
            
            frequencyWaveView.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 18),
            frequencyWaveView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -18),
            frequencyWaveView.widthAnchor.constraint(equalToConstant: 24),
            frequencyWaveView.heightAnchor.constraint(equalToConstant: 18)
        ])
    }
    
    func configure(music: Music?, coverImageData: Data?) {
        guard let music else { return }
        titleLabel.text = music.title
        artistLabel.text = music.artist
        
        if let data = coverImageData, let image = UIImage(data: data) {
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
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: [.curveEaseOut],
            animations: { [weak self] in
                self?.controlButton.transform = .identity
            }, completion: { [weak self] _ in
                self?.controlButton.configuration?.image = buttonState.symbol
            }
        )
    }
}
