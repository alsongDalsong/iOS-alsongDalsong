import UIKit

enum FontName: String {
    case dohyeon = "Dohyeon-Regular"
    case neoDunggeunmoPro = "NeoDunggeunmoPro-Regular"
    case riaSans = "RiaSans-ExtraBold"
    case wantedSansBold = "wantedSans-Bold"
    case tmonMonsori = "TmonMonsori"
}

extension UIFont {
    static func font(_ style: FontName = .dohyeon, ofSize size: CGFloat) -> UIFont {
        guard let customFont = UIFont(name: style.rawValue, size: size) else {
            return UIFont.systemFont(ofSize: size)
        }
        return customFont
    }

    static func font(_ style: FontName = .dohyeon, forTextStyle textStyle: UIFont.TextStyle) -> UIFont {
        let size = UIFont.preferredFont(forTextStyle: textStyle).pointSize
        guard let customFont = UIFont(name: style.rawValue, size: size) else {
            return UIFont.systemFont(ofSize: size)
        }
        return customFont
    }

    @MainActor
    static func responsiveFont(_ view: UIView, _ style: FontName = .dohyeon, _ size: CGFloat) -> UIFont {
        let baseHeight: CGFloat = 874 // iPhone 16 Pro height 기준
        let currentHeight = view.bounds.height
        let scaledSize = (size / baseHeight) * currentHeight

        return UIFont.font(style, ofSize: scaledSize)
    }
}
