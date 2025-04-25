import UIKit

final class ASTextField: UITextField {
    init() {
        super.init(frame: .zero)
    }

    func setConfiguration(
        placeholder: String?,
        backgroundColor: UIColor = .asSystem,
        textFont: FontName = .dohyeon,
        textSize: CGFloat = .responsiveHeight(32)
    ) {
        layer.cornerRadius = .responsiveWidth(12)

        attributedPlaceholder = NSAttributedString(string: placeholder ?? "", attributes: [.foregroundColor: UIColor.lightGray])
        self.backgroundColor = backgroundColor
        font = UIFont.font(textFont, ofSize: textSize)
        textColor = .asForeground
        attributedText?.addObserver(self, forKeyPath: "string", options: .new, context: nil)
        leftView = UIView(frame: CGRect(
            x: .responsiveWidth(0),
            y: .responsiveHeight(0),
            width: .responsiveWidth(10),
            height: .responsiveHeight(0)
        ))
        leftViewMode = .always
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
