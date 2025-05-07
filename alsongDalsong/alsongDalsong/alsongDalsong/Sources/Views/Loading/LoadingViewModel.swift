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
    private let timeoutInterval: TimeInterval = 20.0

    @Published var resource: (avatar: Data?, bgm: Data?)
    @Published var failedToDataDownload: Bool = false

    init(
        avatarRepository: AvatarRepositoryProtocol,
        bgmRepository: BgmRepositoryProtocol,
        dataDownloadRepository: DataDownloadRepositoryProtocol
    ) {
        self.avatarRepository = avatarRepository
        self.bgmRepository = bgmRepository
        self.dataDownloadRepository = dataDownloadRepository
        if NetworkMonitor.shared.isConnected {
            failedToDataDownload = true
        }
        fetchAvatars()
        fetchBgms()
    }

    deinit {
        NetworkMonitor.shared.stopMonitoring()
    }

    func fetchAvatars() {
        Task {
            do {
                failedToDataDownload = false

                avatars = try await withThrowingTimeout(seconds: timeoutInterval) {
                    try await self.avatarRepository.getAvatarUrls()
                }
                guard let randomAvatarUrl = avatars.randomElement() else { return }
                selectedAvatar = randomAvatarUrl

                try await withThrowingTimeout(seconds: timeoutInterval) {
                    await withTaskGroup(of: (Data?, Data?).self) { group in
                        for avatar in self.avatars {
                            group.addTask {
                                async let onboardingData = self.dataDownloadRepository.downloadData(url: avatar.onboarding)
                                async let lobbyData = self.dataDownloadRepository.downloadData(url: avatar.lobby)
                                return await (onboardingData, lobbyData)
                            }
                        }
                    }
                }
                resource.avatar = await self.dataDownloadRepository.downloadData(url: randomAvatarUrl.onboarding)
            } catch {
                failedToDataDownload = true
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
                failedToDataDownload = false

                let bgmUrl = try await withThrowingTimeout(seconds: timeoutInterval) {
                    try await self.bgmRepository.getBgmUrl(for: name.rawValue)
                }
                guard let url = bgmUrl else { return }

                let bgmData = try await withThrowingTimeout(seconds: timeoutInterval) {
                    await self.dataDownloadRepository.downloadData(url: url)
                }

                resource.bgm = bgmData
                guard let bgmData else { failedToDataDownload = true; return }
                AudioHelper.shared.addBgmData(name: name, data: bgmData)

            } catch {
                failedToDataDownload = true
                ErrorHandler.handle(error)
            }
        }
    }
}
