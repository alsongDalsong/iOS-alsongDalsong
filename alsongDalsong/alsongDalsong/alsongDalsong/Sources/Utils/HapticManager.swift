import UIKit

@MainActor
class HapticManager {
    static let shared = HapticManager()
    private let notificationFeedBackGenerator = UINotificationFeedbackGenerator()
    private let selectionFeedBackGenerator = UISelectionFeedbackGenerator()
    
    private init() {}
    
    /// 알림,상태 전달을 위한 햅틱이벤트를 발생시킵니다.
    func notify(type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationFeedBackGenerator.notificationOccurred(type)
    }
    
    /// 버튼 터치 햅틱 이벤트를 발생시킵니다.
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    /// picker와 같이 선택 변화를 나타내는 햅틱 이벤트를 발생시킵니다.
    func selectionChanged() {
        selectionFeedBackGenerator.selectionChanged()
    }
    
    /// 햅틱 엔진을 prepare 합니다.
    func prepare() {
        selectionFeedBackGenerator.prepare()
    }
}
