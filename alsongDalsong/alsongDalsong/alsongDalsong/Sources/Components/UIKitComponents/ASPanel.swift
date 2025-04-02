import UIKit

final class ASPanel: UIView {
    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setupUI() {
        layer.cornerRadius = 12
        layer.borderColor = UIColor.profileViewCircle.cgColor
        layer.borderWidth = 3
        backgroundColor = .asSystem
        setShadow()
    }
}
