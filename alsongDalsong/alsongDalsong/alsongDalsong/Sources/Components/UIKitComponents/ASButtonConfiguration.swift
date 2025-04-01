import UIKit

extension ASButton {
    /// ASButton의 스타일 및 설정 정보를 관리하는 구조체
    struct ASButtonConfiguration {
        let systemImageName: String?
        let text: String?
        let textStyle: UIFont.TextStyle
        let backgroundColor: UIColor?
        let cornerStyle: UIButton.Configuration.CornerStyle
        let baseForegroundColor: UIColor
        init(
            systemImageName: String? = nil,
            text: String? = nil,
            textStyle: UIFont.TextStyle = .largeTitle,
            backgroundColor: UIColor? = nil,
            cornerStyle: UIButton.Configuration.CornerStyle = .medium,
            baseForegroundColor: UIColor = .white
        ) {
            self.systemImageName = systemImageName
            self.text = text
            self.backgroundColor = backgroundColor
            self.textStyle = textStyle
            self.cornerStyle = cornerStyle
            self.baseForegroundColor = baseForegroundColor
        }
        
        /// 버튼의 스타일을 만드는 메소드
        func createConfiguration() -> UIButton.Configuration {
            var config = UIButton.Configuration.gray()
            config.baseForegroundColor = baseForegroundColor
            
            if let systemImageName {
                config.imagePlacement = .leading
                config.image = UIImage(systemName: systemImageName)
                config.imagePadding = 10
                let imageConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .heavy)
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
