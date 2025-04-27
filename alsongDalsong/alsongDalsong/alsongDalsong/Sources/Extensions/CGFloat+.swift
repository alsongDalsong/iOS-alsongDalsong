import Foundation
import UIKit

extension CGFloat {
    @MainActor
    static func responsiveHeight(_ value: CGFloat) -> CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return 0 }
        let baseHeight: CGFloat = 874 // 기준 디바이스 (ex: iPhone 16 Pro)
        let currentHeight = windowScene.screen.bounds.height
        return (value / baseHeight) * currentHeight
    }

    @MainActor
    static func responsiveWidth(_ value: CGFloat) -> CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return 0 }
        let baseWidth: CGFloat = 402
        let currentWidth = windowScene.screen.bounds.width
        return (value / baseWidth) * currentWidth
    }
}
