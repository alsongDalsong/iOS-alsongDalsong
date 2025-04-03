import Combine
import ASEntity
import SwiftUI

final class ModeViewModel: ObservableObject {
    @Published var selectedCard: ModeCard
    @Published var rotation = 0.0
    private var openedMode: [Mode] = [.humming]
    
    init(mode: Mode) {
        let isOpened = openedMode.contains(mode)
        self.selectedCard = ModeCard(mode: mode, isOpened: isOpened)
    }
    
    @MainActor func flipCard(delay: TimeInterval = 0.4) {
        HapticManager.shared.impact(style: .medium)
        rotation = (rotation == 0) ? -180 : 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.selectedCard.isFaceUp.toggle()
        }
    }
    
    struct ModeCard {
        var mode: Mode
        var isFaceUp: Bool = true
        var isOpened: Bool = false
    }
}
