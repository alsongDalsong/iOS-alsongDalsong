import UIKit

final class NicknamePanel: UIView {
    private var textView = UITextView()
    private var nickNameTextFieldMaxCount = 12
    
    var text: String? {
        get {
            return textView.text
        }
        set {
            textView.text = newValue
        }
    }
    
    init() {
        super.init(frame: .zero)
        setupUI()
        setupLayout()
        text = textView.text
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateTextField(placeholder _: String) {
        let paragrapthStyle = NSMutableParagraphStyle()
        paragrapthStyle.alignment = .left
        paragrapthStyle.lineSpacing = -38
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.font(.riaSans, ofSize: 80),
            .foregroundColor: UIColor.onboardingForeground,
            .paragraphStyle: paragrapthStyle,
        ]
        
        let attributedString = NSAttributedString(
            string: "캐릭터와닉네임을선택하라",
            attributes: attributes
        )
        
        textView.attributedText = attributedString
    }
    
    private func setupUI() {
        backgroundColor = UIColor.clear
        textView.backgroundColor = .clear
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
