import ASEntity
import ASLogKit
import ASMusicKit
import ASRepositoryProtocol
import Combine
import Foundation

final class SubmitAnswerViewModel: ObservableObject, @unchecked Sendable {
    @Published private(set) var searchList: [Music] = []
    @Published private(set) var selectedMusic: Music?
    @Published private(set) var isSearching: Bool = false
    @Published private(set) var dueTime: Date?
    @Published private(set) var submissionStatus: (submits: String, total: String) = ("0", "0")
    @Published private(set) var music: Music?
    @Published private(set) var musicData: Data? {
        didSet { isPlaying = true }
    }

    @Published var isPlaying: Bool = false {
        didSet { isPlaying ? playingMusic() : stopMusic() }
    }

    @Published var searchTerm: String = ""

    private let gameStatusRepository: GameStatusRepositoryProtocol
    private let playersRepository: PlayersRepositoryProtocol
    private let recordsRepository: RecordsRepositoryProtocol
    private let submitsRepository: SubmitsRepositoryProtocol
    private let dataDownloadRepository: DataDownloadRepositoryProtocol

    private let musicAPI = ASMusicAPI()
    private var cancellables: Set<AnyCancellable> = []

    private let pageSize: Int = 10
    private var currentPage: Int = 0
    private var isLoadingPage: Bool = false
    private var isAllLoaded: Bool = false

    init(
        gameStatusRepository: GameStatusRepositoryProtocol,
        playersRepository: PlayersRepositoryProtocol,
        recordsRepository: RecordsRepositoryProtocol,
        submitsRepository: SubmitsRepositoryProtocol,
        dataDownloadRepository: DataDownloadRepositoryProtocol
    ) {
        self.gameStatusRepository = gameStatusRepository
        self.playersRepository = playersRepository
        self.recordsRepository = recordsRepository
        self.submitsRepository = submitsRepository
        self.dataDownloadRepository = dataDownloadRepository
        bindGameStatus()
        bindSearchTerm()
    }

    deinit {
        stopMusic()
    }

    private func bindSearchTerm() {
        $searchTerm
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] term in
                Task { [weak self] in
                    if term.isEmpty {
                        await self?.resetSearchList()
                        return
                    }
                    await self?.resetSearchList()
                    try? await self?.searchMusic(text: term)
                }
            }
            .store(in: &cancellables)
    }

    private func bindRecord(on recordOrder: UInt8) {
        recordsRepository.getHumming(on: recordOrder)
            .compactMap { $0 }
            .sink { [weak self] record in
                self?.music = Music(record)
            }
            .store(in: &cancellables)
    }

    private func bindGameStatus() {
        gameStatusRepository.getDueTime()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newDueTime in
                self?.dueTime = newDueTime
            }
            .store(in: &cancellables)

        gameStatusRepository.getRecordOrder()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newRecordOrder in
                self?.bindRecord(on: newRecordOrder)
                self?.bindSubmissionStatus()
            }
            .store(in: &cancellables)
    }

    private func bindSubmissionStatus() {
        let playerPublisher = playersRepository.getPlayersCount()
        let submitsPublisher = submitsRepository.getSubmitsCount()

        playerPublisher.combineLatest(submitsPublisher)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] playersCount, submitsCount in
                let submitStatus = (submits: String(submitsCount), total: String(playersCount))
                self?.submissionStatus = submitStatus
            }
            .store(in: &cancellables)
    }

    func playingMusic() {
        guard let data = musicData else { return }
        Task {
            await AudioHelper.shared.startPlaying(data, option: .full)
        }
    }

    func stopMusic() {
        Task {
            await AudioHelper.shared.stopPlaying()
        }
    }

    func downloadArtwork(url: URL?) async -> Data? {
        guard let url else { return nil }
        return await dataDownloadRepository.downloadData(url: url)
    }

    func downloadMusic(url: URL) {
        Task {
            guard let musicData = await dataDownloadRepository.downloadData(url: url) else {
                return
            }
            await updateMusicData(with: musicData)
        }
    }

    @MainActor
    func randomMusic() async throws {
        do {
            let playlist = try await getPlaylist()
            let randomSongId = playlist.randomElement()!
            selectedMusic = try await musicAPI.getSong(from: randomSongId)
        } catch {
            ErrorHandler.handle(error)
            throw ASError.searchMusicOnSubmit
        }
    }

    func getPlaylist() async throws -> [String] {
        guard let playlistURL = URL(string: "https://firebasestorage.googleapis.com/v0/b/alsongdalsong-boostcamp.firebasestorage.app/o/audios%2FselectMusicRandom%2FsubmitAnswerPlayList.txt?alt=media&token=2c0c2629-ecc8-4895-b205-305c70c38ef6")
        else { return [] }
        guard let musicList = await dataDownloadRepository.downloadData(url: playlistURL) else {
            return []
        }

        let musicListString = String(data: musicList, encoding: .utf8)!
        return musicListString.split(separator: "\n").map { String($0) }
    }

    func searchMusic(text: String) async throws {
        do {
            if text.isEmpty { return }
            await updateIsSearching(with: true)
            let searchList = try await musicAPI.search(for: text, pageSize, 0)
            await updateSearchList(with: searchList)
            await updateIsSearching(with: false)
            currentPage += 1
        } catch {
            ErrorHandler.handle(error)
            throw ASError.searchMusicOnSubmit
        }
    }

    func handleSelectedMusic(with music: Music) {
        selectedMusic = music
        beginPlaying()
    }

    private func beginPlaying() {
        guard let previewUrl = selectedMusic?.previewUrl else { return }
        downloadMusic(url: previewUrl)
    }

    func submitAnswer() async throws {
        guard let selectedMusic else { return }
        do {
            _ = try await submitsRepository.submitAnswer(answer: selectedMusic)
        } catch {
            ErrorHandler.handle(error)
            throw ASError.submitAnswer
        }
    }

    // MARK: - 이부분 부터 RehummingViewModel

    @MainActor
    func resetSearchList() {
        searchList = []
    }

    @MainActor
    private func updateMusicData(with musicData: Data) {
        self.musicData = musicData
    }

    @MainActor
    private func updateSearchList(with searchList: [Music]) {
        self.searchList = searchList
    }

    @MainActor
    private func updateIsSearching(with isSearching: Bool) {
        self.isSearching = isSearching
    }

    func cancelSubscriptions() {
        cancellables.removeAll()
    }

    /// MusicKit을 통해 다음 페이지의 Apple Music 노래를 검색합니다.
    /// - Parameters:
    ///   - currentMusic: 현재 SelectMusicView.swift에서 로딩되고 있는 Music Data
    func fetchNextSearchList(currentMusic: Music? = nil) async {
        guard !isLoadingPage, !isAllLoaded else { return }

        if let currentMusic = currentMusic {
            guard let index = searchList.firstIndex(where: { $0.id == currentMusic.id }),
                  index >= searchList.count - 1 else { return }
        }

        isLoadingPage = true

        defer {
            isLoadingPage = false
        }

        do {
            Logger.debug(currentPage)
            let nextSearchList = try await musicAPI.search(for: searchTerm, pageSize, currentPage * pageSize)

            if nextSearchList.isEmpty {
                isAllLoaded = true
            } else {
                currentPage += 1
                await MainActor.run {
                    let existingIDs = Set(searchList.map { $0.id })
                    let filteredNextSearchList = nextSearchList.filter { !existingIDs.contains($0.id) }
                    searchList.append(contentsOf: filteredNextSearchList)
                }
            }
        } catch {
            ErrorHandler.handle(error)
        }
    }
}
