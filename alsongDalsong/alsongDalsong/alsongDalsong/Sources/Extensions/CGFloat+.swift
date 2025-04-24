import Foundation
import UIKit

extension CGFloat {
    @MainActor
    static func responsiveHeight(_ view: UIView, _ value: CGFloat) -> CGFloat {
        let baseHeight: CGFloat = 874 // 기준 디바이스 (ex: iPhone 16 Pro)
        let currentHeight = view.bounds.height
        return (value / baseHeight) * currentHeight
    }

    @MainActor
    static func responsiveWidth(_ view: UIView, _ value: CGFloat) -> CGFloat {
        let baseWidth: CGFloat = 402
        let currentWidth = view.bounds.width
        return (value / baseWidth) * currentWidth
    }

    @MainActor
    static func responsiveHeight(_ value: CGFloat) -> CGFloat {
        let baseHeight: CGFloat = 874 // 기준 디바이스 (ex: iPhone 16 Pro)
        let currentHeight = UIScreen.main.bounds.height
        return (value / baseHeight) * currentHeight
    }

    @MainActor
    static func responsiveWidth(_ value: CGFloat) -> CGFloat {
        let baseWidth: CGFloat = 402
        let currentWidth = UIScreen.main.bounds.width
        return (value / baseWidth) * currentWidth
    }
}
