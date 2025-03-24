import Foundation
import Combine
import ASEntity
import ASRepositoryProtocol

final class RoomInfoRepository: RoomInfoRepositoryProtocol {
    private var mainRepository: MainRepositoryProtocol
    
    init(mainRepository: MainRepositoryProtocol) {
        self.mainRepository = mainRepository
    }
    
    func getRoomNumber() -> AnyPublisher<String, Never> {
        mainRepository.number
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    func getMode() -> AnyPublisher<Mode, Never> {
        mainRepository.mode
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
}
