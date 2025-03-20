import Combine
import SwiftUI
import UIKit

/// 버튼의 동작을 관리
final class ASButton: UIButton {
    private var cancellables = Set<AnyCancellable>()

    init() {
        super.init(frame: .zero)
        setupButton()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }

    /// 버튼의 UI 관련한 Configuration을 설정하는 메서드
    /// - Parameters:
    ///   - systemImageName: SF Symbol 이미지를 삽입을 원할 경우 "play.fill" 과 같이 systemName 입력.
    ///   - text: 버튼에 쓰일 텍스트
    ///   - textStyle: 버튼에 쓰일 텍스트 스타일
    ///   - backgroundColor: UIColor 형태로 색깔 입력.  (ex .asYellow)
    ///   - cornerStyle: 코너 스타일
    ///   - baseForegroundColor: 글씨 컬러
    func setConfiguration(
        systemImageName: String? = nil,
        text: String? = nil,
        textStyle: UIFont.TextStyle = .largeTitle,
        backgroundColor: UIColor? = nil,
        cornerStyle: UIButton.Configuration.CornerStyle = .medium
    ) {
        var config = UIButton.Configuration.gray()
        config.baseForegroundColor = .asBlack
        config.background.strokeColor = .black
        config.background.strokeWidth = 3
        
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

        setShadow()
        
        config.background.backgroundColorTransformer = UIConfigurationColorTransformer { color in
            color.withAlphaComponent(1.0)
        }

        configurationUpdateHandler = { [weak self] _ in
            guard let self else { return }
            if isHighlighted {
                transform = CGAffineTransform(translationX: 3, y: 3)
                layer.shadowOffset = .zero
            } else {
                transform = .identity
                layer.shadowOffset = CGSize(width: 4, height: 4)
            }
        }
        configuration = config
    }

    private func disable(_ color: UIColor = .systemGray2) {
        configuration?.baseBackgroundColor = color
        isEnabled = false
    }

    func bind(
        to dataSource: Published<Data?>.Publisher,
        baseBackgroundColor: UIColor = .asGreen
    ) {
        dataSource
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] data in
                self?.configuration?.baseBackgroundColor = baseBackgroundColor
                self?.isEnabled = true
            }
            .store(in: &cancellables)
    }
    
    /// 버튼의 활성화 여부를 결정하는 메서드입니다.
    /// - Parameters:
    ///    - isEnabled: `true`면 버튼을 활성화하고, `false`면 버튼을 비활성화합니다.
    func setEnabled(_ isEnabled: Bool) {
        isEnabled ? enableButton() : disableButton()
    }

    enum ASButtonType {
        case needMorePlayers
        case startRecord, recording, reRecord
        case complete
        case submit, submitted
        case startGame
        case startWaiting, endWaiting
        case next
        case nextResultWaiting
        
        var text: String {
            switch self {
                case .needMorePlayers: String(localized: "게임 인원 부족")
                case .startRecord: String(localized: "녹음하기")
                case .recording: String(localized: "녹음중")
                case .reRecord: String(localized: "재녹음")
                case .complete: String(localized: "완료")
                case .submit: String(localized: "제출하기")
                case .submitted: String(localized: "제출 완료")
                case .startGame: String(localized: "시작하기!")
                case .startWaiting: String(localized: "시작 대기 중")
                case .endWaiting: String(localized: "종료 대기 중")
                case .next: String(localized: "다음으로")
                case .nextResultWaiting: String(localized: "다음 결과 대기 중")
            }
        }

        var systemImage: String? {
            switch self {
                case .startGame, .next: "play.fill"
                case .reRecord: "arrow.clockwise"
                default: nil
            }
        }

        var backgroundColor: UIColor? {
            switch self {
                case .needMorePlayers: .asOrange
                case .startRecord: .systemRed
                case .recording: .asLightRed
                case .reRecord: .asOrange
                case .complete: .asYellow
                case .submit: .asGreen
                case .startGame, .next: .asMint
                case .endWaiting, .nextResultWaiting: .systemGray2
                default: nil
            }
        }
        
        var textStyle: UIFont.TextStyle {
            .largeTitle
        }

        var cornerStyle: UIButton.Configuration.CornerStyle {
            .medium
        }
    }
}

private extension ASButton {
    /// Configuration을 적용하는 메서드
    func applyConfiguration() {
      
    }

    /// 버튼을 비활성화하고 색상을 변경하는 메서드
    func disableButton() {
    }

    /// 버튼을 활성화하고 원래 색상으로 되돌리는 메서드
    func enableButton() {
    }

    /// 버튼이 눌렸을 때 효과를 적용하는 메서드
    func applyHighlightEffect() {
        if isHighlighted {
            transform = CGAffineTransform(translationX: 3, y: 3)
            layer.shadowOffset = .zero
        } else {
            transform = .identity
            layer.shadowOffset = CGSize(width: 4, height: 4)
        }
    }
    
    /// 버튼 초기설정을 담당하는 메서드
    func setupButton() {
        setShadow()
        configurationUpdateHandler = { [weak self] _ in
            self?.applyHighlightEffect()
        }
    }
}
