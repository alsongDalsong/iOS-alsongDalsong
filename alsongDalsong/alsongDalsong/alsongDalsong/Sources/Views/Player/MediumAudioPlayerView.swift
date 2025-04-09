import UIKit

enum AudioPlayerType {
    case submit, result
}

final class MediumAudioPlayerView: UIView {
    private let backgroundView = UIView()
    private let coverImageView = UIImageView()
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    private let controlButton = UIButton()
    private let frequencyWaveView = FrequencyWaveView()
    private let stackView = UIStackView()
    
    private var audioPlayerType: AudioPlayerType = .submit
    
    var controlButtonDidTapped: (() -> Void)?
    
    init(type: AudioPlayerType) {
        super.init(frame: .zero)
        self.audioPlayerType = type
        setupUI()
        setupStyle()
        setupLayout()
        
        if audioPlayerType == .submit {
            setupAction()
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupUI() {
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(artistLabel)
        
        addSubview(backgroundView)
        addSubview(coverImageView)
        addSubview(stackView)
        
        if audioPlayerType == .submit {
            addSubview(controlButton)
        }
        
        if audioPlayerType == .result {
            addSubview(frequencyWaveView)
        }
    }
    
    private func setupStyle() {
        backgroundView.layer.cornerRadius = 12
        backgroundView.layer.cornerCurve = .continuous
        backgroundView.backgroundColor = .systemGroupedBackground
        backgroundView.layer.shadowColor = UIColor.gray.cgColor
        backgroundView.layer.shadowOpacity = 0.5
        backgroundView.layer.shadowOffset = CGSize(width: 0, height: 4)
        backgroundView.layer.shadowRadius = 2
        
        if audioPlayerType == .submit {
            backgroundView.backgroundColor = .systemBackground
            backgroundView.layer.borderColor = UIColor.systemGroupedBackground.cgColor
            backgroundView.layer.borderWidth = 3
        }
        
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.layer.cornerRadius = 12
        coverImageView.clipsToBounds = true
        
        titleLabel.textColor = .label
        titleLabel.font = .systemFont(ofSize: 14)
        
        artistLabel.textColor = .secondaryLabel
        artistLabel.font = .systemFont(ofSize: 12)
        
        if audioPlayerType == .submit {
            var buttonConfiguration = UIButton.Configuration.borderless()
            let imageConfiguration = UIImage.SymbolConfiguration(pointSize: 18)
            buttonConfiguration.preferredSymbolConfigurationForImage = imageConfiguration
            buttonConfiguration.baseForegroundColor = .asBlack
            buttonConfiguration.image = UIImage(systemName: "play.fill")
            
            if #available(iOS 17.0, *) { controlButton.isSymbolAnimationEnabled = true }
            controlButton.configuration = buttonConfiguration
        }
        
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 4
    }
    
    private func setupAction() {
        controlButton.addAction(UIAction { [weak self] _ in
            self?.controlButtonDidTapped?()
        }, for: .touchUpInside)
    }
    
    private func setupLayout() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        coverImageView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            coverImageView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            coverImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            coverImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            coverImageView.heightAnchor.constraint(equalToConstant: 60),
            coverImageView.widthAnchor.constraint(equalToConstant: 60),
            
            stackView.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 10),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        if audioPlayerType == .submit {
            controlButton.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                controlButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
                controlButton.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        }
        
        if audioPlayerType == .result {
            frequencyWaveView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                stackView.trailingAnchor.constraint(equalTo: frequencyWaveView.leadingAnchor, constant: -10),
                
                frequencyWaveView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
                frequencyWaveView.widthAnchor.constraint(equalToConstant: 20),
                frequencyWaveView.heightAnchor.constraint(equalToConstant: 16),
                frequencyWaveView.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        }
    }
}

// MARK: - Configure Methods

extension MediumAudioPlayerView {
    func configure(title: String, artist: String, imageData: Data?) {
        titleLabel.text = title
        artistLabel.text = artist
        
        if let data = imageData, let image = UIImage(data: data) {
            coverImageView.image = image
            coverImageView.backgroundColor = .clear
        } else {
            coverImageView.image = nil
            coverImageView.backgroundColor = .systemGray4
        }
    }
    
    func configure(normalizedFrequencyAmplitudes: [Float]) {
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
