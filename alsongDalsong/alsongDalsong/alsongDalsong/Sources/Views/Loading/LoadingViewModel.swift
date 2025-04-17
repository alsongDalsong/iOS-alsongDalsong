import ASEntity
import ASLogKit
import ASRepositoryProtocol
import Foundation

final class LoadingViewModel: @unchecked Sendable {
    private let avatarRepository: AvatarRepositoryProtocol
    private let bgmRepository: BgmRepositoryProtocol
    private let dataDownloadRepository: DataDownloadRepositoryProtocol
    private(set) var avatars: [AvatarPair] = []
    private(set) var selectedAvatar: AvatarPair?

    init(
        avatarRepository: AvatarRepositoryProtocol,
        bgmRepository: BgmRepositoryProtocol,
        dataDownloadRepository: DataDownloadRepositoryProtocol
    ) {
        self.avatarRepository = avatarRepository
        self.bgmRepository = bgmRepository
        self.dataDownloadRepository = dataDownloadRepository
        fetchAvatars()
        fetchBgms()
    }

    @Published var avatarData: Data?

    func fetchAvatars() {
        Task {
            do {
                avatars = try await avatarRepository.getAvatarUrls()
                guard let randomAvatarUrl = avatars.randomElement() else { return }
                selectedAvatar = randomAvatarUrl

                await withTaskGroup(of: (Data?, Data?).self) { group in
                    for avatar in avatars {
                        group.addTask { [weak self] in
                            guard let self else { return (nil, nil) }
                            async let onboardingData = dataDownloadRepository.downloadData(url: avatar.onboarding)
                            async let lobbyData = dataDownloadRepository.downloadData(url: avatar.lobby)
                            return await (onboardingData, lobbyData)
                        }
                    }
                }

                avatarData = await dataDownloadRepository.downloadData(url: randomAvatarUrl.onboarding)
            } catch {
                ErrorHandler.handle(error)
            }
        }
    }

    func fetchBgms() {
        for name in Bgm.allCases {
            addBgm(name: name)
        }
    }

    private func addBgm(name: Bgm) {
        Task {
            do {
                let bgm = try await bgmRepository.getBgmUrl(for: name.rawValue)
                guard let bgmUrl = bgm else { return }
                guard let bgmData = await dataDownloadRepository.downloadData(url: bgmUrl) else { return }
                AudioHelper.shared.addBgmData(name: name, data: bgmData)
            } catch {
                ErrorHandler.handle(error)
            }
        }
    }
}
