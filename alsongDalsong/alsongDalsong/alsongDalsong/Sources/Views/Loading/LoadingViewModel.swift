import ASLogKit
import ASRepositoryProtocol
import Foundation

final class LoadingViewModel: @unchecked Sendable {
    private let avatarRepository: AvatarRepositoryProtocol
    private let bgmRepository: BgmRepositoryProtocol
    private let dataDownloadRepository: DataDownloadRepositoryProtocol
    private(set) var avatars: [URL] = []
    private(set) var bgm: URL?
    private(set) var selectedAvatar: URL?

    init(
        avatarRepository: AvatarRepositoryProtocol,
        bgmRepository: BgmRepositoryProtocol,
        dataDownloadRepository: DataDownloadRepositoryProtocol
    ) {
        self.avatarRepository = avatarRepository
        self.bgmRepository = bgmRepository
        self.dataDownloadRepository = dataDownloadRepository
        fetchAvatars()
        fetchBgm()
    }

    @Published var avatarData: Data?
    @Published var bgmData: Data?

    func fetchAvatars() {
        Task {
            do {
                avatars = try await avatarRepository.getAvatarUrls()

                guard let randomAvatarUrl = avatars.randomElement() else { return }
                selectedAvatar = randomAvatarUrl

                await withTaskGroup(of: Data?.self) { group in
                    for url in avatars {
                        group.addTask { [weak self] in
                            return await self?.dataDownloadRepository.downloadData(url: url)
                        }
                    }
                }

                avatarData = await dataDownloadRepository.downloadData(url: randomAvatarUrl)
            } catch {
                ErrorHandler.handle(error)
            }
        }
    }

    func fetchBgm() {
        Task {
            do {
                bgm = try await bgmRepository.getBgmUrl(for: "onboarding")

                guard let bgmUrl = bgm else { return }

                bgmData = await dataDownloadRepository.downloadData(url: bgmUrl)
            } catch {
                ErrorHandler.handle(error)
            }
        }
    }
}
