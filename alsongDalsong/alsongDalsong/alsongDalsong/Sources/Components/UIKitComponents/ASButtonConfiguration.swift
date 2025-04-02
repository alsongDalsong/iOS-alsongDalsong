import UIKit

extension ASButton {
    /// ASButton의 스타일 및 설정 정보를 관리하는 구조체
    struct ASButtonConfiguration {
        let systemImageName: String?
        let imageSize: CGFloat
        let text: String?
        let textStyle: UIFont.TextStyle
        let backgroundColor: UIColor?
        let cornerStyle: UIButton.Configuration.CornerStyle
        let baseForegroundColor: UIColor
        let strokeColor: UIColor?
        let strokeWidth: CGFloat
      
        init(
            systemImageName: String? = nil,
            imageSize: CGFloat = 20,
            text: String? = nil,
            textStyle: UIFont.TextStyle = .largeTitle,
            backgroundColor: UIColor? = nil,
            cornerStyle: UIButton.Configuration.CornerStyle = .medium,
            baseForegroundColor: UIColor = .white,
            strokeColor: UIColor? = nil,
            strokeWidth: CGFloat = 0
        ) {
            self.systemImageName = systemImageName
            self.imageSize = imageSize
            self.text = text
            self.backgroundColor = backgroundColor
            self.textStyle = textStyle
            self.cornerStyle = cornerStyle
            self.baseForegroundColor = baseForegroundColor
            self.strokeColor = strokeColor
            self.strokeWidth = strokeWidth
        }
        
        /// 버튼의 스타일을 만드는 메소드
        func createConfiguration() -> UIButton.Configuration {
            var config = UIButton.Configuration.gray()
            config.baseForegroundColor = baseForegroundColor
            config.background.strokeColor = strokeColor
            config.background.strokeWidth = strokeWidth
            
            if let systemImageName {
                config.imagePlacement = .leading
                config.image = UIImage(systemName: systemImageName)
                config.imagePadding = 0
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
            
            config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
            config.cornerStyle = cornerStyle
            
            config.background.backgroundColorTransformer = UIConfigurationColorTransformer { color in
                color.withAlphaComponent(1.0)
            }
            
            return config
        }
    }
}
