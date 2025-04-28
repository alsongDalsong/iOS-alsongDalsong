import UIKit
import Combine

final class MusicPanelView: UIView {
    private let albumImageView = UIImageView()
    private let musicNameLabel = UILabel()
    private let singerNameLabel = UILabel()
    private let titleLabel = UILabel()
    private var cancellables = Set<AnyCancellable>()

    init() {
        super.init(frame: .zero)
        setupView()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupConstraints()
    }
    
    func bind(
        to dataSource: Published<Result>.Publisher
    ) {
        dataSource
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] result in
                let answer = result.answer
                self?.musicNameLabel.text = answer?.title
                self?.singerNameLabel.text = answer?.artist
                self?.setImage(with: answer?.artworkData)
            }
            .store(in: &cancellables)
    }
    
    private func setImage(with data: Data?) {
        guard let data else { return }
        albumImageView.image = UIImage(data: data)
    }

    private func setupView() {
        backgroundColor = .asSystem
        
        titleLabel.text = String(localized: "정답은...")
        titleLabel.font = .font(ofSize: .responsiveHeight(24))
        titleLabel.textColor = .asForeground
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        albumImageView.contentMode = .scaleAspectFill
        albumImageView.layer.cornerRadius = .responsiveWidth(6)
        albumImageView.clipsToBounds = true
        albumImageView.translatesAutoresizingMaskIntoConstraints = false
        albumImageView.backgroundColor = .secondarySystemBackground
        addSubview(albumImageView)

        musicNameLabel.font = .font(.wantedSansBold, ofSize: .responsiveHeight(24))
        musicNameLabel.textColor = .asForeground
        musicNameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(musicNameLabel)

        singerNameLabel.font = .font(.wantedSansBold, ofSize: .responsiveHeight(24))
        singerNameLabel.textColor = UIColor.gray
        singerNameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(singerNameLabel)
        
        layer.cornerRadius = .responsiveWidth(12)
        layer.shadowColor = UIColor.asShadow.cgColor
        layer.shadowOffset = CGSize(width: .responsiveWidth(4), height: .responsiveHeight(4))
        layer.shadowRadius = .responsiveWidth(0)
        layer.shadowOpacity = 1.0
        layer.borderWidth = .responsiveWidth(3)
        layer.borderColor = UIColor.black.cgColor
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: .responsiveHeight(16)),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .responsiveWidth(16)),

            albumImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: .responsiveHeight(12)),
            albumImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .responsiveWidth(16)),
            albumImageView.widthAnchor.constraint(equalToConstant: .responsiveWidth(60)),
            albumImageView.heightAnchor.constraint(equalToConstant: .responsiveHeight(60)),

            musicNameLabel.topAnchor.constraint(equalTo: albumImageView.topAnchor),
            musicNameLabel.leadingAnchor.constraint(equalTo: albumImageView.trailingAnchor, constant: .responsiveWidth(15)),
            musicNameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: .responsiveWidth(-16)),

            singerNameLabel.topAnchor.constraint(equalTo: musicNameLabel.bottomAnchor, constant: .responsiveHeight(4)),
            singerNameLabel.leadingAnchor.constraint(equalTo: albumImageView.trailingAnchor, constant: .responsiveWidth(15)),
            singerNameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: .responsiveWidth(-16))
        ])
    }
}
