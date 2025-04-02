import UIKit
import SwiftUI

final class ASAvatarView: UIView {
    private var imageView = UIImageView()
    
    init(backgroundColor: UIColor = .asMint) {
        super.init(frame: .zero)
        setup(backgroundColor: backgroundColor)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup(backgroundColor: UIColor) {
        layer.masksToBounds = true
        layer.backgroundColor = CGColor(gray: 0, alpha: 0)
        
        clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    func setImage(imageData: Data?) {
        guard let imageData else { return }
        imageView.image = UIImage(data: imageData)
    }
}
