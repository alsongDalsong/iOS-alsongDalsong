import ASContainer
import ASEntity
import ASRepositoryProtocol
import Combine
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

    private var cancellables = Set<AnyCancellable>()
    private var viewModel: AudioPlayerViewModel?

    private var audioPlayerType: AudioPlayerType = .result

    var controlButtonDidTapped: (() -> Void)?

    init(type: AudioPlayerType) {
        super.init(frame: .zero)
        self.audioPlayerType = type
        setupView()
        setupStyle()
        setupLayout()
        bindWithPlayer()

        if audioPlayerType == .submit {
            setupAction()
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func bind(to datasource: MappedAnswer) {
        viewModel = AudioPlayerViewModel(previewData: datasource.previewData, artworkData: datasource.artworkData)
        configure(
            titleLabelFont: .boldSystemFont(ofSize: .responsiveHeight(16)),
            artistLabelFont: .systemFont(ofSize: .responsiveHeight(12))
        )
        bindViewModel()
        configure(title: datasource.title, artist: datasource.artist)
    }

    func bind(to dataSource: Published<Bool>.Publisher) {
        dataSource
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard GameAudioHelper.shared.isEnginePlaying else { return }

                if state {
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
        viewModel?.$artworkData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.configure(imageData: $0) }
            .store(in: &cancellables)

        viewModel?.$normalizedFrequencyAmplitudes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.configure(normalizedFrequencyAmplitudes: $0) }
            .store(in: &cancellables)

        viewModel?.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.configure(with: $0) }
            .store(in: &cancellables)
    }

    private func setupView() {
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
        backgroundView.layer.cornerRadius = .responsiveWidth(12)
        backgroundView.layer.cornerCurve = .continuous
        backgroundView.backgroundColor = .systemGroupedBackground
        backgroundView.layer.shadowColor = UIColor.gray.cgColor
        backgroundView.layer.shadowOpacity = 0.5
        backgroundView.layer.shadowOffset = CGSize(width: .responsiveWidth(0), height: .responsiveHeight(4))
        backgroundView.layer.shadowRadius = .responsiveWidth(2)

        if audioPlayerType == .submit {
            backgroundView.backgroundColor = .systemBackground
            backgroundView.layer.borderColor = UIColor.systemGroupedBackground.cgColor
            backgroundView.layer.borderWidth = .responsiveWidth(3)
        }

        coverImageView.contentMode = .scaleAspectFill
        coverImageView.layer.cornerRadius = .responsiveWidth(12)
        coverImageView.clipsToBounds = true

        titleLabel.textColor = .label
        titleLabel.font = .boldSystemFont(ofSize: .responsiveHeight(18))

        artistLabel.textColor = .secondaryLabel
        artistLabel.font = .systemFont(ofSize: .responsiveHeight(14))

        if audioPlayerType == .submit {
            var buttonConfiguration = UIButton.Configuration.borderless()
            let imageConfiguration = UIImage.SymbolConfiguration(pointSize: .responsiveWidth(18))
            buttonConfiguration.preferredSymbolConfigurationForImage = imageConfiguration
            buttonConfiguration.baseForegroundColor = .asForeground
            buttonConfiguration.image = UIImage(systemName: "play.fill")

            if #available(iOS 17.0, *) { controlButton.isSymbolAnimationEnabled = true }
            controlButton.configuration = buttonConfiguration
        }

        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = .responsiveHeight(4)
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

            coverImageView.topAnchor.constraint(equalTo: topAnchor, constant: .responsiveHeight(10)),
            coverImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: .responsiveHeight(-10)),
            coverImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .responsiveWidth(10)),
            coverImageView.widthAnchor.constraint(equalTo: coverImageView.heightAnchor),

            stackView.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: .responsiveWidth(10)),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        if audioPlayerType == .submit {
            controlButton.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                controlButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: .responsiveWidth(-10)),
                controlButton.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        }

        if audioPlayerType == .result {
            frequencyWaveView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                stackView.trailingAnchor.constraint(equalTo: frequencyWaveView.leadingAnchor, constant: .responsiveWidth(-10)),

                frequencyWaveView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: .responsiveWidth(-20)),
                frequencyWaveView.widthAnchor.constraint(equalToConstant: .responsiveWidth(20)),
                frequencyWaveView.heightAnchor.constraint(equalToConstant: .responsiveHeight(16)),
                frequencyWaveView.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        }
    }
    
    func unbind() {
        controlButton.isEnabled = false
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        viewModel?.unbindAudioHelper()
    }
}

// MARK: - Configure Methods

extension MediumAudioPlayerView {
    func configure(title: String?, artist: String?) {
        titleLabel.text = title
        artistLabel.text = artist
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

    func configure(normalizedFrequencyAmplitudes: [Float]) {
        frequencyWaveView.normalizedFrequencyAmplitudes = normalizedFrequencyAmplitudes
    }

    func configure(with isPlaying: Bool) {
        let buttonState: AudioControlButtonState = isPlaying ? .stop : .play
        controlButton.configuration?.image = buttonState.symbol
    }

    func configure(titleLabelFont: UIFont, artistLabelFont: UIFont) {
        titleLabel.font = titleLabelFont
        artistLabel.font = artistLabelFont
    }
}
