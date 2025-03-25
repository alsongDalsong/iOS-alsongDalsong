import Foundation
import Combine
import ASEntity
import ASRepositoryProtocol

final class GameStatusRepository: GameStatusRepositoryProtocol {
    private var mainRepository: MainRepositoryProtocol
    
    init(mainRepository: MainRepositoryProtocol) {
        self.mainRepository = mainRepository
    }
    
    func getStatus() -> AnyPublisher<Status?, Never> {
        mainRepository.status
            .eraseToAnyPublisher()
    }
    
    func getRecordOrder() -> AnyPublisher<UInt8, Never> {
        mainRepository.recordOrder
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    func getDueTime() -> AnyPublisher<Date, Never> {
        mainRepository.dueTime
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
}
