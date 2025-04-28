import UIKit

extension ASButton {
    /// ASButton의 스타일 및 설정 정보를 관리하는 구조체
    @MainActor
    struct ASButtonConfiguration {
        let systemImageName: String?
        let imageSize: CGFloat
        let imageColor: UIColor?
        let text: String?
        let textStyle: UIFont.TextStyle
        let backgroundColor: UIColor?
        let cornerStyle: UIButton.Configuration.CornerStyle
        let baseForegroundColor: UIColor
        let strokeColor: UIColor?
        let strokeWidth: CGFloat
        let shadowColor: UIColor?
        let shadowHeight: CGFloat
      
        init(
            systemImageName: String? = nil,
            imageSize: CGFloat = .responsiveWidth(20),
            imageColor: UIColor? = nil,
            text: String? = nil,
            textStyle: UIFont.TextStyle = .largeTitle,
            backgroundColor: UIColor? = nil,
            cornerStyle: UIButton.Configuration.CornerStyle = .medium,
            baseForegroundColor: UIColor = .white,
            strokeColor: UIColor? = nil,
            strokeWidth: CGFloat = .responsiveWidth(0),
            shadowColor: UIColor? = nil,
            shadowHeight: CGFloat = .responsiveHeight(8)
        ) {
            self.systemImageName = systemImageName
            self.imageSize = imageSize
            self.imageColor = imageColor
            self.text = text
            self.backgroundColor = backgroundColor
            self.textStyle = textStyle
            self.cornerStyle = cornerStyle
            self.baseForegroundColor = baseForegroundColor
            self.strokeColor = strokeColor
            self.strokeWidth = strokeWidth
            self.shadowColor = shadowColor
            self.shadowHeight = shadowHeight
        }
        
        /// 버튼의 스타일을 만드는 메소드
        @MainActor
        func createConfiguration() -> UIButton.Configuration {
            var config = UIButton.Configuration.gray()
            config.baseForegroundColor = baseForegroundColor
            config.background.strokeColor = strokeColor
            config.background.strokeWidth = strokeWidth

            if let systemImageName {
                config.imagePlacement = .leading
                config.image = UIImage(systemName: systemImageName)?
                    .withRenderingMode(.alwaysOriginal)
                    .withTintColor(imageColor ?? baseForegroundColor)
                config.imagePadding = .responsiveWidth(8)
                let imageConfig = UIImage.SymbolConfiguration(pointSize: imageSize, weight: .heavy)
                config.preferredSymbolConfigurationForImage = imageConfig
            }
            
            if let backgroundColor {
                config.baseBackgroundColor = backgroundColor
            }
            
            if let text {
                var titleAttr = AttributedString(text)
                titleAttr.font = UIFont.font(forTextStyle: textStyle)
                config.attributedTitle = titleAttr
            }
            
            config.contentInsets = NSDirectionalEdgeInsets(
                top: .responsiveHeight(0),
                leading: .responsiveWidth(12),
                bottom: .responsiveHeight(0),
                trailing: .responsiveWidth(12)
            )
            config.cornerStyle = cornerStyle
            
            config.background.backgroundColorTransformer = UIConfigurationColorTransformer { color in
                color.withAlphaComponent(1.0)
            }
            
            return config
        }
    }
}
