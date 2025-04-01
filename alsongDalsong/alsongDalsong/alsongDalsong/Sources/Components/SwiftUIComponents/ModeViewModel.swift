import Combine
import ASEntity

final class ModeViewModel: ObservableObject {
    @Published var selectedCard: ModeCard
    
    init() {
        self.selectedCard = ModeCard(mode: .humming)
    }
    
    struct ModeCard {
        var mode: Mode
        var isFaceUp: Bool = true
    }
}
