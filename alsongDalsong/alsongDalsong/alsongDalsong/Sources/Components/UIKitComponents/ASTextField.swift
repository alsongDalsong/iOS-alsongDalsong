import UIKit

final class ASTextField: UITextField {
    init() {
        super.init(frame: .zero)
    }

    func setConfiguration(
        placeholder: String?,
        backgroundColor: UIColor = .asSystem,
        textFont: FontName = .dohyeon,
        textSize: CGFloat = 32
    ) {
        layer.cornerRadius = 12

        attributedPlaceholder = NSAttributedString(string: placeholder ?? "", attributes: [.foregroundColor: UIColor.lightGray])
        self.backgroundColor = backgroundColor
        font = UIFont.font(textFont, ofSize: textSize)
        textColor = .asForeground
        attributedText?.addObserver(self, forKeyPath: "string", options: .new, context: nil)
        leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        leftViewMode = .always
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
