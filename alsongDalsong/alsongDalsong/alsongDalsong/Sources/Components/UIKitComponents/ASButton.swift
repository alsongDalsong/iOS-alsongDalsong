import Combine
import SwiftUI
import UIKit

/// 버튼의 동작을 관리
final class ASButton: UIButton {
    private var configurationData: ASButtonConfiguration?
    private var cancellables = Set<AnyCancellable>()
    private var isAnimating = false

    init() {
        super.init(frame: .zero)
        setupButton()
        addTarget(self, action: #selector(playClickSound), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
        addTarget(self, action: #selector(playClickSound), for: .touchUpInside)
    }

    /// 버튼의 UI 관련한 Configuration을 설정하는 메서드
    /// - Parameters:
    ///   - systemImageName: SF Symbol 이미지를 삽입을 원할 경우 "play.fill" 과 같이 systemName 입력.
    ///   - text: 버튼에 쓰일 텍스트
    ///   - textStyle: 버튼에 쓰일 텍스트 스타일
    ///   - backgroundColor: UIColor 형태로 색깔 입력.  (e.g. .asYellow)
    ///   - cornerStyle: 코너 스타일
    ///   - baseForegroundColor: 글씨 컬러
    func setConfiguration(
        systemImageName: String? = nil,
        imageSize: CGFloat = 20,
        text: String? = nil,
        textStyle: UIFont.TextStyle = .largeTitle,
        backgroundColor: UIColor? = nil,
        cornerStyle: UIButton.Configuration.CornerStyle = .large,
        baseForegroundColor: UIColor = .white,
        shadowColor: UIColor = .buttonShadowOfDefault,
        shadowHeight: CGFloat = 8,
        strokeColor: UIColor? = nil,
        strokeWidth: CGFloat = 0
    ) {
        configurationData = ASButtonConfiguration(
            systemImageName: systemImageName,
            imageSize: imageSize,
            text: text ?? configurationData?.text,
            textStyle: textStyle,
            backgroundColor: backgroundColor,
            cornerStyle: cornerStyle,
            baseForegroundColor: baseForegroundColor,
            strokeColor: strokeColor,
            strokeWidth: strokeWidth,
            shadowColor: shadowColor,
            shadowHeight: shadowHeight
        )
        setShadow(color: shadowColor, width: 0, height: shadowHeight)
        applyConfiguration()
    }

    /// 버튼의 UI 관련한 Configuration을 설정하는 메서드
    func setConfiguration(
        _ type: ASButtonType? = nil,
        shadowHeight: CGFloat = 8
    ) {
        configurationData = ASButtonConfiguration(
            systemImageName: type?.systemImage,
            text: type?.text,
            textStyle: type?.textStyle ?? .largeTitle,
            backgroundColor: type?.backgroundColor,
            cornerStyle: type?.cornerStyle ?? .medium,
            shadowColor: type?.shadowColor ?? .buttonShadowOfDefault,
            shadowHeight: shadowHeight
        )
        setShadow(color: (type?.shadowColor) ?? .buttonShadowOfDefault, width: 0, height: shadowHeight)
        applyConfiguration()
    }

    func bind(
        to dataSource: Published<Data?>.Publisher
    ) {
        dataSource
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] _ in
                let backgroundColor = self?.configurationData?.backgroundColor
                let shadowColor = self?.configurationData?.shadowColor ?? .buttonShadowOfDefault
                self?.setConfiguration(backgroundColor: backgroundColor, shadowColor: shadowColor)
                self?.isEnabled = true
            }
            .store(in: &cancellables)
    }

    /// 버튼을 비활성화하면서 스타일을 변경하는 메서드입니다.
    func setDisabledState() {
        let previousConfiguration = configurationData
        configurationData = ASButtonConfiguration(
            systemImageName: configurationData?.systemImageName,
            text: configurationData?.text,
            textStyle: configurationData?.textStyle ?? .largeTitle,
            backgroundColor: .systemGray2,
            cornerStyle: configurationData?.cornerStyle ?? .medium,
            baseForegroundColor: configurationData?.baseForegroundColor ?? .white
        )
        setShadow(color: .buttonShadowOfDefault, width: 0)
        isEnabled = false
        applyConfiguration()
        configurationData = previousConfiguration
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
            case .startRecord, .recording, .reRecord, .startGame, .next, .submitted: .asLightRed
            case .complete: .asLightSky
            case .submit: .asLightSky
            case .endWaiting, .nextResultWaiting, .needMorePlayers: .systemGray2
            default: nil
            }
        }

        var textStyle: UIFont.TextStyle {
            .largeTitle
        }

        var cornerStyle: UIButton.Configuration.CornerStyle {
            .medium
        }

        var shadowColor: UIColor? {
            switch self {
            case .startRecord, .recording, .reRecord, .startGame, .next, .submitted:
                .buttonShadowOfRed
            case .submit, .complete:
                .buttonShadowOfBlue
            default: nil
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        guard isEnabled else {
            setShadow(color: .buttonShadowOfDefault, width: 0)
            return
        }
        if let shadowColor = configurationData?.shadowColor {
            let resolved = shadowColor.resolvedColor(with: traitCollection)
            setShadow(color: resolved, width: 0)
        }
    }
}

private extension ASButton {
    /// Configuration을 적용하는 메서드
    func applyConfiguration() {
        configuration = configurationData?.createConfiguration()
    }

    /// 버튼이 눌렸을 때 효과를 적용하는 메서드
    func applyHighlightEffect() {
        if isHighlighted {
            transform = CGAffineTransform(translationX: 0, y: configurationData?.shadowHeight ?? 8)
            layer.shadowOffset = .zero
        } else {
            transform = .identity
            layer.shadowOffset = CGSize(width: 0, height: configurationData?.shadowHeight ?? 8)
        }
    }

    /// 버튼 초기설정을 담당하는 메서드
    func setupButton() {
        configurationUpdateHandler = { [weak self] _ in
            self?.applyHighlightEffect()
        }
    }
}

// MARK: - Animations

extension ASButton {
    func animateConfirmation(temporaryText: String, delay: TimeInterval = 1.5) {
        guard !isAnimating, let originConfiguration = configurationData else { return }
        isAnimating = true
        let updatedConfiguration = ASButtonConfiguration(
            systemImageName: "checkmark.circle.fill",
            imageSize: 24,
            imageColor: .asGreen,
            text: temporaryText,
            textStyle: originConfiguration.textStyle,
            backgroundColor: originConfiguration.backgroundColor,
            cornerStyle: originConfiguration.cornerStyle,
            baseForegroundColor: originConfiguration.baseForegroundColor,
            strokeColor: originConfiguration.strokeColor,
            strokeWidth: originConfiguration.strokeWidth
        )

        UIView.transition(
            with: self,
            duration: 0.3,
            options: .transitionCrossDissolve,
            animations: {
                self.configurationData = updatedConfiguration
                self.applyConfiguration()
                if #available(iOS 17.0, *) {
                    guard let symbolImageView = self.imageView else { return }
                    symbolImageView.addSymbolEffect(.bounce)
                }
            },
            completion: nil
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            UIView.transition(
                with: self,
                duration: 0.3,
                options: .transitionCrossDissolve,
                animations: {
                    self.configurationData = originConfiguration
                    self.applyConfiguration()
                },
                completion: { _ in
                    self.isAnimating = false
                }
            )
        }
    }
}

// MARK: - Click Sound

extension ASButton {
    @objc func playClickSound() {
        EffectAudioHelper.shared.playButtonClick()
    }
}
