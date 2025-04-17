import ASLogKit
import ASMusicKit
import ASRepositoryProtocol
import Foundation

final class OnboardingViewModel: @unchecked Sendable {
    private let roomActionRepository: RoomActionRepositoryProtocol
    private let dataDownloadRepository: DataDownloadRepositoryProtocol
    private var avatars: [(onboarding: URL, lobby: URL)] = []
    private var selectedAvatar: (onboarding: URL, lobby: URL)?

    @Published var nickname: String = ""
    @Published var avatarData: Data?
    @Published var buttonEnabled: Bool = false

    init(roomActionRepository: RoomActionRepositoryProtocol,
         dataDownloadRepository: DataDownloadRepositoryProtocol,
         avatars: [(onboarding: URL, lobby: URL)],
         selectedAvatar: (onboarding: URL, lobby: URL)?,
         avatarData: Data?)
    {
        self.roomActionRepository = roomActionRepository
        self.dataDownloadRepository = dataDownloadRepository
        self.avatars = avatars
        self.selectedAvatar = selectedAvatar
        self.avatarData = avatarData
    }

    func setNickname(with nickname: String) {
        self.nickname = nickname
    }

    func refreshAvatars() {
        Task {
            let filteredAvatars = avatars.filter { $0.onboarding != selectedAvatar?.onboarding }
            guard let randomAvatarUrl = filteredAvatars.randomElement() else { return }
            selectedAvatar = randomAvatarUrl
            avatarData = await dataDownloadRepository.downloadData(url: randomAvatarUrl.onboarding)
        }
    }

    func playBgm() {
        AudioHelper.shared.playBgm(name: .onboarding)
    }

    @MainActor
    func authorizeAppleMusic() {
        let musicAPI = ASMusicAPI()
        Task {
            do {
                let _ = try await musicAPI.search(for: "뉴진스", 1, 1)
            } catch {
                ErrorHandler.handle(error)
            }
        }
    }

    @MainActor
    func joinRoom(roomNumber id: String) async throws -> String? {
        guard let selectedAvatar else { return nil }
        buttonEnabled = false
        do {
            buttonEnabled = try await roomActionRepository.joinRoom(nickname: nickname, avatar: selectedAvatar.lobby, roomNumber: id)
            return id
        } catch {
            buttonEnabled = true

            ErrorHandler.handle(error)
            throw ASError.joinRoom(description: error.localizedDescription)
        }
    }

    @MainActor
    func createRoom() async throws -> String? {
        guard let selectedAvatar else { return nil }
        buttonEnabled = false
        do {
            let roomNumber = try await roomActionRepository.createRoom(nickname: nickname, avatar: selectedAvatar.lobby)
            return try await joinRoom(roomNumber: roomNumber)
        } catch {
            buttonEnabled = true

            ErrorHandler.handle(error)
            throw ASError.createRoom
        }
    }
}
