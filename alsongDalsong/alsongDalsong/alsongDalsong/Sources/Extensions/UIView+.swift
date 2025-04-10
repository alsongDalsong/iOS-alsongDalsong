import UIKit

extension UIView {
    /// 버튼에 지정된 그림자를 추가하는 메서드
    func setShadow(color: UIColor = .asShadow, width: CGFloat = 4, height: CGFloat = 4, radius: CGFloat = 0, opacity: Float = 1) {
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOpacity = opacity
        self.layer.shadowOffset = CGSize(width: width, height: height)
        self.layer.shadowRadius = radius
    }

    /// 뷰에 Shake 애니메이션을 추가하는 메서드
    func shake(duration: CFTimeInterval = 0.3, repeatCount: Float = 2) {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = duration / 10
        animation.repeatCount = repeatCount
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: self.center.x - 8, y: self.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: self.center.x + 8, y: self.center.y))
        layer.add(animation, forKey: "shake")
    }
}
