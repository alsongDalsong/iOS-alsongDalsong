import ASContainer
import ASEntity
import ASRepositoryProtocol
import Combine
import UIKit

final class SelectAnswerButton: UIButton {
    private let coverImageView = UIImageView()
    private let songTitleLabel = UILabel()
    private let artistLabel = UILabel()
    private let controlButton = UIButton()
    private let frequencyWaveView = FrequencyWaveView()
    private let stackView = UIStackView()

    private var cancellables = Set<AnyCancellable>()
    private var viewModel: AudioPlayerViewModel? = nil

    var controlButtonDidTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupStyle()
        setupLayout()
        bindWithPlayer()
        setupAction()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupStyle()
        setupLayout()
        bindWithPlayer()
        setupAction()
    }

    func bind(to dataSource: Published<Music?>.Publisher) {
        dataSource
            .receive(on: DispatchQueue.main)
            .sink { [weak self] music in
                guard let self else { return }

                if music == nil { return }

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
        viewModel?.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.configure(with: $0) }
            .store(in: &cancellables)

        viewModel?.$artworkData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.configure(imageData: $0) }
            .store(in: &cancellables)

        viewModel?.$normalizedFrequencyAmplitudes
            .sink { [weak self] in self?.configure(normalizedFrequencyAmplitudes: $0) }
            .store(in: &cancellables)
    }

    private func setupView() {
        stackView.addArrangedSubview(songTitleLabel)
        stackView.addArrangedSubview(artistLabel)

        addSubview(coverImageView)
        addSubview(stackView)
        addSubview(controlButton)
        addSubview(frequencyWaveView)

        stackView.isHidden = true
        coverImageView.isHidden = true
        controlButton.isHidden = true
        frequencyWaveView.isHidden = true

        coverImageView.isUserInteractionEnabled = false
        stackView.isUserInteractionEnabled = false
        controlButton.isUserInteractionEnabled = false
        frequencyWaveView.isUserInteractionEnabled = false
    }

    private func setupStyle() {
        layer.cornerRadius = .responsiveWidth(12)
        layer.cornerCurve = .continuous
        backgroundColor = .systemBackground
        layer.borderColor = UIColor.systemGroupedBackground.cgColor
        layer.borderWidth = .responsiveWidth(3)
        layer.shadowColor = UIColor.gray.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: .responsiveWidth(0), height: .responsiveHeight(4))
        layer.shadowRadius = .responsiveWidth(2)

        coverImageView.contentMode = .scaleAspectFill
        coverImageView.layer.cornerRadius = .responsiveWidth(12)
        coverImageView.clipsToBounds = true
        coverImageView.backgroundColor = .systemGray4

        songTitleLabel.textColor = .label
        songTitleLabel.font = .boldSystemFont(ofSize: .responsiveHeight(18))

        artistLabel.textColor = .secondaryLabel
        artistLabel.font = .systemFont(ofSize: .responsiveHeight(14))

        var buttonConfiguration = UIButton.Configuration.borderless()
        let imageConfiguration = UIImage.SymbolConfiguration(pointSize: .responsiveWidth(18))
        buttonConfiguration.preferredSymbolConfigurationForImage = imageConfiguration
        buttonConfiguration.baseForegroundColor = .asForeground
        buttonConfiguration.image = UIImage(systemName: "play.fill")

        if #available(iOS 17.0, *) { controlButton.isSymbolAnimationEnabled = true }
        controlButton.configuration = buttonConfiguration

        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = .responsiveHeight(4)

        configuration = .plain()
        var titleAttribute = AttributedString("정답을 선택해 주세요")
        titleAttribute.foregroundColor = .label
        titleAttribute.font = .systemFont(ofSize: .responsiveHeight(18), weight: .semibold)
        configuration?.attributedTitle = titleAttribute

        configurationUpdateHandler = { [weak self] _ in
            self?.applyHighlightEffect()
        }
    }

    private func setupLayout() {
        coverImageView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        controlButton.translatesAutoresizingMaskIntoConstraints = false
        frequencyWaveView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: .responsiveHeight(80)),

            coverImageView.topAnchor.constraint(equalTo: topAnchor, constant: .responsiveHeight(10)),
            coverImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: .responsiveHeight(-10)),
            coverImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .responsiveWidth(10)),
            coverImageView.heightAnchor.constraint(equalToConstant: .responsiveHeight(60)),
            coverImageView.widthAnchor.constraint(equalToConstant: .responsiveWidth(60)),

            stackView.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: .responsiveWidth(10)),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: .responsiveWidth(-10)),

            controlButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: .responsiveWidth(-20)),
            controlButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            controlButton.widthAnchor.constraint(equalToConstant: .responsiveWidth(44)),
            controlButton.heightAnchor.constraint(equalToConstant: .responsiveWidth(44)),

            frequencyWaveView.trailingAnchor.constraint(equalTo: controlButton.leadingAnchor, constant: .responsiveWidth(-20)),
            frequencyWaveView.widthAnchor.constraint(equalToConstant: .responsiveWidth(20)),
            frequencyWaveView.heightAnchor.constraint(equalToConstant: .responsiveHeight(16)),
            frequencyWaveView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    private func setupAction() {
        controlButton.addAction(UIAction { [weak self] _ in
            self?.controlButtonDidTapped?()
        }, for: .touchUpInside)
    }

    private func applyHighlightEffect() {
        if isHighlighted {
            transform = CGAffineTransform(translationX: .responsiveWidth(0), y: .responsiveHeight(4))
            layer.shadowColor = UIColor.clear.cgColor
        } else {
            transform = .identity
            layer.shadowColor = UIColor.gray.cgColor
        }
    }

    func configure(title: String?, artist: String?) {
        songTitleLabel.text = title
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

        stackView.isHidden = false
        coverImageView.isHidden = false
        controlButton.isHidden = false
        frequencyWaveView.isHidden = false

        controlButton.isUserInteractionEnabled = true
        frequencyWaveView.isUserInteractionEnabled = true

        titleLabel?.isHidden = true
    }

    func configure(normalizedFrequencyAmplitudes: [Float]) {
        frequencyWaveView.normalizedFrequencyAmplitudes = normalizedFrequencyAmplitudes
    }

    func configure(with isPlaying: Bool) {
        let buttonState: AudioControlButtonState = isPlaying ? .stop : .play
        controlButton.configuration?.image = buttonState.symbol
    }
    
    func unbind() {
        controlButton.isEnabled = false
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        viewModel?.unbindAudioHelper()
    }
}

final class SampleSelectionAnswerButtonViewController: UIViewController {
    private let button1 = SelectAnswerButton()
    private let button2 = SelectAnswerButton()

    private var count = 1

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        view.addSubview(button1)
        view.addSubview(button2)

        button1.translatesAutoresizingMaskIntoConstraints = false
        button2.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            button1.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            button1.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            button1.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            button2.topAnchor.constraint(equalTo: button1.bottomAnchor, constant: 40),
            button2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            button2.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])

        button2.configure(title: "Title \(count)", artist: "Artest \(count)")
        button2.configure(imageData: nil)
        button2.addAction(UIAction { [self] _ in
            count += 1
            button2.configure(title: "Title \(count)", artist: "Artest \(count)")
            button2.configure(imageData: nil)
        }, for: .touchUpInside)
    }
}

@available(iOS 17.0, *)
#Preview {
    SampleSelectionAnswerButtonViewController()
}
