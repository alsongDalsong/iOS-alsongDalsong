import ASLogKit
import ASNetworkKit
import ASRepositoryProtocol
 
final class BgmRepository: BgmRepositoryProtocol {
    // TODO: - Container로 주입
    private let storageManager: ASFirebaseStorageProtocol
 
    init(
        storageManager: ASFirebaseStorageProtocol
    ) {
        self.storageManager = storageManager
    }
 
    func getBgmUrl(for path: String) async throws -> URL? {
        do {
            let url = try await self.storageManager.getBgmUrl(for: path)
            return url
        } catch {
            ErrorHandler.handle(error)
            throw ASRepositoryError.getBgmUrls
        }
    }
}
