import ASEntity
import ASRepositoryProtocol

public final class AvatarMockRepository: AvatarRepositoryProtocol {
    public init() {}

    public func getAvatarUrls() async throws -> [URL] {
        [
            Player.playerStub1,
            Player.playerStub2,
            Player.playerStub3,
            Player.playerStub4
        ].compactMap(\.avatarUrl)
    }
}
