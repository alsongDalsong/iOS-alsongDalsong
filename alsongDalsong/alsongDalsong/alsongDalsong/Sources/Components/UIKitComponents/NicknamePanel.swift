import UIKit

final class NicknamePanel: UIView {
    private var textView = UITextView()
    private var nickNameTextFieldMaxCount = 12
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
        paragrapthStyle.lineSpacing = -38

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.font(.riaSans, ofSize: 80),
            .foregroundColor: UIColor.onboardingForeground,
            .paragraphStyle: paragrapthStyle,
        ]
        
        let attributedString = NSAttributedString(
            string: placeholder,
            attributes: attributes
        )
        
        textView.attributedText = attributedString
    }

    func setupDelegate(_ delegate: UITextViewDelegate) {
        self.textView.delegate = delegate
    }

    private func setupUI() {
        backgroundColor = UIColor.clear
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        updateTextField(placeholder: "캐릭터와닉네임을선택하라")
        addSubview(textView)
    }
    
    private func setupLayout() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            textView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
        ])
    }
}

extension NicknamePanel: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)

        if updatedText.count > nickNameTextFieldMaxCount {
            return false
        }

        if updatedText.components(separatedBy: .newlines).count > nickNameTextFieldMaxLine {
            return false
        }
        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        text = textView.text ?? ""
    }
}
