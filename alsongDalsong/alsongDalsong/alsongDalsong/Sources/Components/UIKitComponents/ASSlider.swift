import UIKit

class ASSlider: UISlider {
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
         // Drawing code
     }
     */
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(origin: bounds.origin, size: CGSize(width: bounds.width, height: .responsiveHeight(20)))
    }
    
    override func minimumValueImageRect(forBounds bounds: CGRect) -> CGRect {
        // 원하는 위치와 크기로 조정
        return CGRect(x: bounds.minX - 40, y: bounds.minY, width: 30, height: 20)
    }
    
    override func maximumValueImageRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.maxX + 10, y: bounds.minY, width: 30, height: 20)
    }

    func setUI() {
        minimumTrackTintColor = .asOrange
        minimumValueImage = UIImage(systemName: "speaker.wave.1.fill")
        maximumValueImage = UIImage(systemName: "speaker.wave.3.fill")
    }
}
