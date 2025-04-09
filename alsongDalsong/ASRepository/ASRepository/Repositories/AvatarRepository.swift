import ASEntity
import ASLogKit
import ASNetworkKit
import ASRepositoryProtocol

final class AvatarRepository: AvatarRepositoryProtocol {
    // TODO: - Container로 주입
    private let storageManager: ASFirebaseStorageProtocol

    init(
        storageManager: ASFirebaseStorageProtocol
    ) {
        self.storageManager = storageManager
    }

    func getAvatarUrls() async throws -> [AvatarPair] {
        do {
            let urls = try await self.storageManager.getAvatarUrls()
            return urls
        } catch {
            ErrorHandler.handle(error)
            throw ASRepositoryError.getAvatarUrls
        }
    }
}
