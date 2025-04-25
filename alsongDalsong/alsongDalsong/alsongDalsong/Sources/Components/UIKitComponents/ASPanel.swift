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
        layer.cornerRadius = .responsiveWidth(12)
        layer.borderColor = UIColor.profileViewCircle.cgColor
        layer.borderWidth = .responsiveWidth(3)
        backgroundColor = .asSystem
        setShadow()
    }
}
