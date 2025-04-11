import ASEntity
import ASRepositoryProtocol

public final class AvatarMockRepository: AvatarRepositoryProtocol {
    public init() {}

    public func getAvatarUrls() async throws -> [AvatarPair] {
        [
            Player.playerStub1,
            Player.playerStub2,
            Player.playerStub3,
            Player.playerStub4
        ].compactMap({ player in
            guard let avatarUrl = player.avatarUrl else { return nil }
            return AvatarPair(onboarding: avatarUrl, lobby: avatarUrl)
        })
    }
}
