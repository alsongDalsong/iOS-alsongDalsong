import UIKit

final class ASSlider: UISlider {
    private let trackLayer = CALayer()
    private let fillLayer = CALayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let trackHeight: CGFloat = .responsiveHeight(20)
        
        return CGRect(
            x: bounds.origin.x,
            y: (bounds.height - trackHeight) / 2,
            width: bounds.width,
            height: trackHeight
        )
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let trackRect = trackRect(forBounds: bounds)
        trackLayer.frame = trackRect
        updateFillLayer()
        
        if let thumbView = subviews.last {
            bringSubviewToFront(thumbView)
        }
    }
    
    private func setupUI() {
        /// 기본 track 숨김
        setMinimumTrackImage(UIImage(), for: .normal)
        setMaximumTrackImage(UIImage(), for: .normal)
        
        trackLayer.backgroundColor = UIColor.systemGray5.cgColor
        trackLayer.cornerRadius = .responsiveHeight(20) / 2
        layer.addSublayer(trackLayer)
        
        fillLayer.backgroundColor = UIColor.asBlue.cgColor
        fillLayer.cornerRadius = .responsiveHeight(20) / 2
        layer.addSublayer(fillLayer)
        
        addTarget(self, action: #selector(valueChanged), for: .valueChanged)
    }
    
    private func updateFillLayer() {
        /// frame update 시 자동으로 애니메이션이 되어 애니메이션 제거
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let trackRect = trackRect(forBounds: bounds)
        let thumbRect = thumbRect(forBounds: bounds, trackRect: trackRect, value: value)
        let fillWidth = thumbRect.midX - trackRect.origin.x
        
        fillLayer.frame = CGRect(
            x: trackRect.origin.x,
            y: trackRect.origin.y,
            width: fillWidth,
            height: trackRect.height
        )
        
        CATransaction.commit()
    }
    
    @objc private func valueChanged() {
        updateFillLayer()
    }
}
