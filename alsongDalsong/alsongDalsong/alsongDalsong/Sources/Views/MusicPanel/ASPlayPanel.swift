import ASEntity
import UIKit

final class WaveView: UIView {
    private var shapeLayers: [CAShapeLayer] = []
    
    private let shapeLayersCount = 6
    private let initialHeight: CGFloat = 3
    private let spacing: CGFloat = 1
    
    private var initialWidth: CGFloat {
        (bounds.width - spacing * CGFloat(shapeLayersCount - 1)) / CGFloat(shapeLayersCount)
    }
    
    init() {
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if shapeLayers.isEmpty {
            setup()
        }
    }
    
    private func setup() {
        for i in 0..<shapeLayersCount {
            let shapeLayer = CAShapeLayer()
            let xPosition = CGFloat(i) * (initialWidth + spacing)
            
            let rect = CGRect(
                x: xPosition,
                y: (bounds.height - initialHeight) / 2,
                width: initialWidth,
                height: initialHeight
            )
            
            shapeLayer.path = UIBezierPath(roundedRect: rect, cornerRadius: 2).cgPath
            shapeLayer.fillColor = UIColor.lightGray.cgColor
            shapeLayers.append(shapeLayer)
            layer.addSublayer(shapeLayer)
        }
    }

    func configure(_ fftMagnitudes: [Float]) {
        guard fftMagnitudes.count == 6 else { return }
        
        for (index, shapeLayer) in shapeLayers.enumerated() {
            let magnitude = CGFloat(fftMagnitudes[index]) / 10
            let newHeight = min(bounds.height, max(initialHeight, magnitude))
            
            let xPosition = CGFloat(index) * (initialWidth + spacing)
            
            let newRect = CGRect(
                x: xPosition,
                y: (bounds.height - newHeight) / 2,
                width: initialWidth,
                height: newHeight
            )
            
            let animation = CASpringAnimation(keyPath: "path")
            animation.damping = 6
            animation.initialVelocity = 0.5
            animation.stiffness = 80
            animation.mass = 0.8
            animation.duration = animation.settlingDuration
            animation.fromValue = shapeLayer.path
            animation.toValue = UIBezierPath(roundedRect: newRect, cornerRadius: 1).cgPath
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            
            shapeLayer.add(animation, forKey: "animation")
            shapeLayer.path = UIBezierPath(roundedRect: newRect, cornerRadius: 1).cgPath
        }
    }
}

final class PlayProgressView: UIView {
    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    
    var progress: CGFloat = 0 {
        didSet { updateProgress() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        layer.addSublayer(trackLayer)
        layer.addSublayer(progressLayer)
        
        trackLayer.backgroundColor = UIColor.systemGray5.cgColor
        progressLayer.backgroundColor = UIColor.darkGray.cgColor
        
        [trackLayer, progressLayer].forEach {
            $0.cornerRadius = 3
            $0.masksToBounds = true
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        trackLayer.frame = bounds
        progressLayer.frame = CGRect(
            origin: .zero,
            size: CGSize(width: progressLayer.frame.width, height: bounds.height)
        )
    }
    
    private func updateProgress() {
        let targetWidth = bounds.width * progress
        let springAnimation = CASpringAnimation(keyPath: "bounds.size.width")
        
        springAnimation.stiffness = 80
        springAnimation.initialVelocity = 0.3
        springAnimation.fromValue = progressLayer.bounds.width
        springAnimation.toValue = targetWidth
        springAnimation.duration = springAnimation.settlingDuration
        
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.progressLayer.bounds.size.width = targetWidth
        }
        progressLayer.add(springAnimation, forKey: "widthAnimation")
        CATransaction.commit()
    }
}

enum ASPlayPanelType {
    case large, answer, result
}

enum ASPlayButtonState {
    case play, stop
    
    var symbol: UIImage? {
        switch self {
        case .play: UIImage(systemName: "play.fill")
        case .stop: UIImage(systemName: "stop.fill")
        }
    }
}

final class ASPlayPanel: UIView {
    private let imageView = UIImageView()
    private let backgroundView = UIView()
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    private let playButton = UIButton()
    private let progressView = PlayProgressView()
    private let waveView = WaveView()
    private let stackView = UIStackView()
    
    private var playPanelType: ASPlayPanelType = .large
    
    var onPlayButtonTapped: (() -> Void)?
    
    init(type: ASPlayPanelType) {
        playPanelType = type
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
        
        addSubview(backgroundView)
        addSubview(stackView)
        addSubview(progressView)
        addSubview(playButton)
        addSubview(waveView)
    }
    
    func setupStyle() {
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
        playButton.configuration = buttonConfiguration
        
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 4
    }
    
    func setupAction() {
        playButton.addAction(UIAction { [weak self] _ in
            self?.onPlayButtonTapped?()
        }, for: .touchUpInside)
    }
    
    func setupLayout() {
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        playButton.translatesAutoresizingMaskIntoConstraints = false
        waveView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            
            progressView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 12),
            progressView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 8),
            
            playButton.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 12),
            playButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            playButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            
            waveView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            waveView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            waveView.widthAnchor.constraint(equalToConstant: 20),
            waveView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }
    
    func configure(by music: Music?) {
        guard let music else { return }
        titleLabel.text = music.title
        artistLabel.text = music.artist
    }
    
    func configure(progress: Double, magnitudes: [Float]) {
        let progress = CGFloat(progress)
        
        UIView.animate(withDuration: 0.3) {
            self.progressView.progress = progress
        }
        
        waveView.configure(magnitudes)
    }
    
    func configure(with buttonState: ASPlayButtonState) {
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: [.curveEaseOut],
            animations: { [weak self] in
                self?.playButton.transform = .identity
            }, completion: { [weak self] _ in
                self?.playButton.configuration?.image = buttonState.symbol
            }
        )
    }
}
