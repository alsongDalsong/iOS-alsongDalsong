import UIKit

final class PlayProgressView: UIView {
    private let trackLayer = CALayer()
    private let progressLayer = CALayer()
    
    private let progressMaskLayer = CAShapeLayer()

    var progress: CGFloat = 0 {
        didSet {
            self.updateProgress()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        trackLayer.frame = bounds
        trackLayer.cornerRadius = bounds.height / 2

        let width = bounds.width * progress
        progressLayer.frame = CGRect(x: 0, y: 0, width: width, height: bounds.height)

        updateProgressMask()
    }

    private func setupLayers() {
        trackLayer.backgroundColor = UIColor.systemGray5.cgColor
        layer.addSublayer(trackLayer)

        progressLayer.backgroundColor = UIColor.darkGray.cgColor
        layer.addSublayer(progressLayer)

        progressLayer.mask = progressMaskLayer
    }

    private func updateProgress() {
        let clamped = min(max(progress, 0.01), 1)
        let newWidth = bounds.width * clamped
        let newFrame = CGRect(x: 0, y: 0, width: newWidth, height: bounds.height)

        let positionAnimation = CABasicAnimation(keyPath: "position")
        positionAnimation.fromValue = NSValue(cgPoint: progressLayer.presentation()?.position ?? progressLayer.position)
        positionAnimation.toValue = NSValue(cgPoint: CGPoint(x: newWidth / 2, y: bounds.height / 2))
        positionAnimation.duration = 0.25
        positionAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        let boundsAnimation = CABasicAnimation(keyPath: "bounds")
        boundsAnimation.fromValue = NSValue(cgRect: progressLayer.presentation()?.bounds ?? progressLayer.bounds)
        boundsAnimation.toValue = NSValue(cgRect: CGRect(x: 0, y: 0, width: newWidth, height: bounds.height))
        boundsAnimation.duration = 0.25
        boundsAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        progressLayer.add(positionAnimation, forKey: "position")
        progressLayer.add(boundsAnimation, forKey: "bounds")

        progressLayer.position = CGPoint(x: newWidth / 2, y: bounds.height / 2)
        progressLayer.bounds = CGRect(x: 0, y: 0, width: newWidth, height: bounds.height)

        updateProgressMask()
    }

    private func updateProgressMask() {
        let height = bounds.height
        let minWidth = progressLayer.bounds.width
        
        guard progress > 0 else {
            progressMaskLayer.path = nil
            return
        }
        
        /// 최소 width 보장 (둥글게 보이기 위해)
        let displayWidth = max(minWidth, height)
        let corners: UIRectCorner = (progress >= 1.0) ? .allCorners : [.topLeft, .bottomLeft]
        
        let bezierPath = UIBezierPath(
            roundedRect: CGRect(x: 0, y: 0, width: displayWidth, height: height),
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: height / 2, height: height / 2)
        )

        progressMaskLayer.path = bezierPath.cgPath
    }
}
