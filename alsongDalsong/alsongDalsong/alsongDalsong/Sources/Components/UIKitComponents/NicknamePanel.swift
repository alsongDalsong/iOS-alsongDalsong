import UIKit

final class NicknamePanel: UIView {
    private var textView = UITextView()
    private var nickNameTextFieldMaxLine = 3

    @Published var text: String?

    init() {
        super.init(frame: .zero)
        setupUI()
        setupLayout()
        textView.delegate = self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateTextField(placeholder: String) {
        let paragrapthStyle = NSMutableParagraphStyle()
        paragrapthStyle.alignment = .center
        paragrapthStyle.lineSpacing = .responsiveHeight(-20)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.font(.tmonMonsori, ofSize: .responsiveHeight(80)),
            .foregroundColor: UIColor.onboardingForeground,
            .paragraphStyle: paragrapthStyle,
        ]
        
        let attributedString = NSAttributedString(
            string: placeholder,
            attributes: attributes
        )
        
        textView.attributedText = attributedString
        text = placeholder
    }

    func setupDelegate(_ delegate: UITextViewDelegate) {
        self.textView.delegate = delegate
    }

    private func setupUI() {
        backgroundColor = UIColor.clear
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        textView.returnKeyType = .done

        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = .responsiveHeight(0)

        updateTextField(placeholder: "캐릭터와닉네임을설정하라")
        addSubview(textView)
    }
    
    private func setupLayout() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .responsiveWidth(4)),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: .responsiveWidth(-4)),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: .responsiveHeight(-4)),
            textView.topAnchor.constraint(equalTo: topAnchor, constant: .responsiveHeight(4)),
        ])
    }
}

extension NicknamePanel: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }

        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)

        let font = textView.font ?? UIFont.font(.tmonMonsori, ofSize: .responsiveHeight(80))
        let textWidth = textView.bounds.width
        let lineCount = numberOfLines(for: updatedText, font: font, maxWidth: textWidth)

        if lineCount > nickNameTextFieldMaxLine {
            textView.shake()
            return false
        }

        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        text = textView.text ?? ""
    }

    private func numberOfLines(for text: String, font: UIFont, maxWidth: CGFloat) -> Int {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let constraintSize = CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude)

        let boundingBox = (text as NSString).boundingRect(
            with: constraintSize,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )

        return Int(ceil(boundingBox.height / font.lineHeight))
    }
}
