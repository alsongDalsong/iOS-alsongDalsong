import ASLogKit
import ASRepositoryProtocol
import Foundation

final class LoadingViewModel: @unchecked Sendable {
    private let avatarRepository: AvatarRepositoryProtocol
    private let dataDownloadRepository: DataDownloadRepositoryProtocol
    private(set) var avatars: [URL] = []
    private(set) var selectedAvatar: URL?

    init(
        avatarRepository: AvatarRepositoryProtocol,
        dataDownloadRepository: DataDownloadRepositoryProtocol
    ) {
        self.avatarRepository = avatarRepository
        self.dataDownloadRepository = dataDownloadRepository
        fetchAvatars()
    }
    
    @Published var avatarData: Data?
    
    func fetchAvatars() {
        Task {
            do {
                avatars = try await avatarRepository.getAvatarUrls()

                guard let randomAvatarUrl = avatars.randomElement() else { return }
                selectedAvatar = randomAvatarUrl

                await withTaskGroup(of: Data?.self) { group in
                    avatars.forEach { url in
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
}
