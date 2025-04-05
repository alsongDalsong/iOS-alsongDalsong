import UIKit

final class PlayProgressView: UIView {
    private let trackShapeLayer = CAShapeLayer()
    private let progressShapeLayer = CAShapeLayer()
    
    var progress: CGFloat = 0 {
        didSet { updateProgressShapeLayer() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
        setupStyle()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
        setupStyle()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        trackShapeLayer.frame = bounds
        progressShapeLayer.frame = CGRect(
            origin: .zero,
            size: CGSize(width: progressShapeLayer.frame.width, height: bounds.height)
        )
    }
    
    private func setupLayer() {
        layer.addSublayer(trackShapeLayer)
        layer.addSublayer(progressShapeLayer)
    }
    
    private func setupStyle() {
        trackShapeLayer.backgroundColor = UIColor.systemGray5.cgColor
        trackShapeLayer.cornerRadius = 4
        trackShapeLayer.masksToBounds = true
        
        progressShapeLayer.backgroundColor = UIColor.darkGray.cgColor
        progressShapeLayer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        progressShapeLayer.cornerRadius = 4
    }
    
    private func updateProgressShapeLayer() {
        let targetWidth = bounds.width * progress
        let rect = CGRect(x: 0, y: 0, width: targetWidth, height: bounds.height)
        
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: progress == 1 ? [.allCorners] : [.topLeft, .bottomLeft],
            cornerRadii: CGSize(width: 4, height: 4)
        )
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        progressShapeLayer.mask = maskLayer
        
        let animation = CABasicAnimation(keyPath: "bounds.size.width")
        animation.fromValue = progressShapeLayer.bounds.width
        animation.toValue = targetWidth
        
        progressShapeLayer.add(animation, forKey: "widthAnimation")
        progressShapeLayer.bounds.size.width = targetWidth
    }
}
