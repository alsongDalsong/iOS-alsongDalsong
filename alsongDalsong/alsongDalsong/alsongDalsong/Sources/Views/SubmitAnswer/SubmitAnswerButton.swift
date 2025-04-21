import UIKit

final class SubmitAnswerButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStyle()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupStyle()
        setupLayout()
    }
    
    private func setupStyle() {
        layer.cornerRadius = 12
        layer.cornerCurve = .continuous
        backgroundColor = .systemBackground
        layer.borderColor = UIColor.systemGroupedBackground.cgColor
        layer.borderWidth = 3
        layer.shadowColor = UIColor.gray.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 2
        
        configuration = .plain()
        var titleAttr = AttributedString("정답을 선택해 주세요")
        titleAttr.foregroundColor = .label
        titleAttr.font = .systemFont(ofSize: 18, weight: .semibold)
        configuration?.attributedTitle = titleAttr
                
        configurationUpdateHandler = { [weak self] _ in
            self?.applyHighlightEffect()
        }
    }
    
    private func setupLayout() {
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    private func applyHighlightEffect() {
        if isHighlighted {
            transform = CGAffineTransform(translationX: 0, y: 4)
            layer.shadowColor = UIColor.clear.cgColor
        } else {
            transform = .identity
            layer.shadowColor = UIColor.gray.cgColor
        }
    }
}
