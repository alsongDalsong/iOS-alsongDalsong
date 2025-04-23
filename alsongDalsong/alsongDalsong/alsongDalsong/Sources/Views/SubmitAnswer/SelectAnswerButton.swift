import UIKit

final class SelectAnswerButton: UIButton {
    private let coverImageView = UIImageView()
    private let songTitleLabel = UILabel()
    private let artistLabel = UILabel()
    private let stackView = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupStyle()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupStyle()
        setupLayout()
    }
    
    private func setupView() {
        stackView.addArrangedSubview(songTitleLabel)
        stackView.addArrangedSubview(artistLabel)

        addSubview(coverImageView)
        addSubview(stackView)
        
        stackView.isHidden = true
        coverImageView.isHidden = true
        
        coverImageView.isUserInteractionEnabled = false
        stackView.isUserInteractionEnabled = false
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
        
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.layer.cornerRadius = 12
        coverImageView.clipsToBounds = true
        coverImageView.backgroundColor = .systemGray4

        songTitleLabel.textColor = .label
        songTitleLabel.font = .systemFont(ofSize: 14)

        artistLabel.textColor = .secondaryLabel
        artistLabel.font = .systemFont(ofSize: 12)

        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 4
        
        configuration = .plain()
        var titleAttribute = AttributedString("정답을 선택해 주세요")
        titleAttribute.foregroundColor = .label
        titleAttribute.font = .systemFont(ofSize: 18, weight: .semibold)
        configuration?.attributedTitle = titleAttribute
                
        configurationUpdateHandler = { [weak self] _ in
            self?.applyHighlightEffect()
        }
    }
    
    private func setupLayout() {
        coverImageView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 80),
            
            coverImageView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            coverImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            coverImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            coverImageView.heightAnchor.constraint(equalToConstant: 60),
            coverImageView.widthAnchor.constraint(equalToConstant: 60),

            stackView.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 10),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
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
    
    func configure(title: String?, artist: String?, imageData: Data?) {
        songTitleLabel.text = title
        artistLabel.text = artist
        
        if let data = imageData, let image = UIImage(data: data) {
            coverImageView.image = image
            coverImageView.backgroundColor = .clear
        } else {
            coverImageView.image = nil
            coverImageView.backgroundColor = .systemGray4
        }
        
        stackView.isHidden = false
        coverImageView.isHidden = false
        
        titleLabel?.isHidden = true
    }
}

final class SampleSelectionAnswerButtonViewController: UIViewController {
    private let button1 = SelectAnswerButton()
    private let button2 = SelectAnswerButton()
    
    private var count = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        view.addSubview(button1)
        view.addSubview(button2)
        
        button1.translatesAutoresizingMaskIntoConstraints = false
        button2.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button1.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            button1.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            button1.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            button2.topAnchor.constraint(equalTo: button1.bottomAnchor, constant: 40),
            button2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            button2.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
        
        button2.configure(title: "Title \(count)", artist: "Artest \(count)", imageData: nil)
        button2.addAction(UIAction { [self] _ in
            count += 1
            button2.configure(title: "Title \(count)", artist: "Artest \(count)", imageData: nil)
        }, for: .touchUpInside)
    }
}

@available(iOS 17.0, *)
#Preview {
    SampleSelectionAnswerButtonViewController()
}
