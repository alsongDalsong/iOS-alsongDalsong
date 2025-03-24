import Foundation
import ASNetworkKit
import Combine
import ASEntity
import ASRepositoryProtocol

final class PlayersRepository: PlayersRepositoryProtocol {
    private var mainRepository: MainRepositoryProtocol
    
    init(mainRepository: MainRepositoryProtocol) {
        self.mainRepository = mainRepository
    }

    func getMyID() -> String? { ASFirebaseAuth.myID }

    func getPlayers() -> AnyPublisher<[Player], Never> {
        mainRepository.players
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    func getPlayersCount() -> AnyPublisher<Int, Never> {
        mainRepository.players
            .compactMap { $0 }
            .map { $0.count }
            .eraseToAnyPublisher()
    }

    func getHost() -> AnyPublisher<Player, Never> {
        mainRepository.host
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    func isHost() -> AnyPublisher<Bool, Never> {
        self.getHost()
            .map { $0.id == ASFirebaseAuth.myID }
            .eraseToAnyPublisher()
    }
}

