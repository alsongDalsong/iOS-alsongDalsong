import ASEntity
import ASRepositoryProtocol
import Combine

public final class GameStateMockRepository: GameStateRepositoryProtocol {
    private let gameStatePublisher = CurrentValueSubject<ASEntity.GameState?, Never>(nil)

    public init(state: GameState) {
        switch state.mode {
        case .humming:
            gameStatePublisher.send(state)
        default:
            break
        }
    }

    public func getGameState() -> AnyPublisher<ASEntity.GameState?, Never> {
        gameStatePublisher
            .eraseToAnyPublisher()
    }
    
    public func receiveKickOut() -> AnyPublisher<Bool, Never> {
        CurrentValueSubject<Bool, Never>(false)
            .eraseToAnyPublisher()
    }

    public func getPlayersCount() -> AnyPublisher<Int, Never> {
        CurrentValueSubject<Int, Never>(1)
            .eraseToAnyPublisher()
    }
}
