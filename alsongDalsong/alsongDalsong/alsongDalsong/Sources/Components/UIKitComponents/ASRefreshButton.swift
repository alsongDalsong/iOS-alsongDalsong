import UIKit

final class ASRefreshButton: UIButton {
    
    init(size: CGFloat) {
        super.init(frame: .zero)
        setConfiguration(size: size)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setConfiguration(size: CGFloat) {
        var config = UIButton.Configuration.gray()

        config.baseBackgroundColor = .asSystem
        config.baseForegroundColor = .asBlack

        config.imagePlacement = .all
        config.image = UIImage(systemName: "arrow.clockwise")
        config.cornerStyle = .capsule

        let imageConfig = UIImage.SymbolConfiguration(pointSize: size, weight: .bold)
        config.preferredSymbolConfigurationForImage = imageConfig
        config.cornerStyle = .capsule
        
        configurationUpdateHandler = { [weak self] _ in
            guard let self else { return }
            if isHighlighted {
                transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            } else {
                transform = .identity
            }
        }

        configuration = config
    }
}
