import ASEntity
import ASLogKit
import ASMusicKit
import ASRepositoryProtocol
import Combine
import Foundation

final class SelectMusicViewModel: ObservableObject, @unchecked Sendable {
    @Published private(set) var searchList: [Music] = []
    @Published private(set) var isSearching: Bool = false
    @Published private(set) var dueTime: Date?
    @Published private(set) var selectedMusic: Music?
    @Published private(set) var submissionStatus: (submits: String, total: String) = ("0", "0")

    @Published private(set) var musicData: Data? {
        didSet { isPlaying = true }
    }

    @Published var isPlaying: Bool = false {
        didSet { isPlaying ? playMusic() : stopMusic() }
    }
    
    @Published var searchTerm: String = ""
    
    private let playersRepository: PlayersRepositoryProtocol
    private let answersRepository: AnswersRepositoryProtocol
    private let gameStatusRepository: GameStatusRepositoryProtocol
    private let dataDownloadRepository: DataDownloadRepositoryProtocol

    private let musicAPI = ASMusicAPI()
    private var cancellables = Set<AnyCancellable>()

    private let pageSize: Int = 10
    private var currentPage: Int = 0
    private var isLoadingPage: Bool = false
    private var isAllLoaded: Bool = false

    init(
        playersRepository: PlayersRepositoryProtocol,
        answerRepository: AnswersRepositoryProtocol,
        gameStatusRepository: GameStatusRepositoryProtocol,
        dataDownloadRepository: DataDownloadRepositoryProtocol
    ) {
        self.playersRepository = playersRepository
        self.answersRepository = answerRepository
        self.gameStatusRepository = gameStatusRepository
        self.dataDownloadRepository = dataDownloadRepository
        bindGameStatus()
        bindSubmissionStatus()
        bindSearchTerm()
    }
    
    private func bindGameStatus() {
        gameStatusRepository.getDueTime()
            .map { Optional($0) }
            .receive(on: DispatchQueue.main)
            .assign(to: &$dueTime)
    }
    
    private func bindSubmissionStatus() {
        let playerPublisher = playersRepository.getPlayersCount()
        let answersPublisher = answersRepository.getAnswersCount()

        playerPublisher.combineLatest(answersPublisher)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] playersCount, answersCount in
                let submitStatus = (submits: String(answersCount), total: String(playersCount))
                self?.submissionStatus = submitStatus
            }
            .store(in: &cancellables)
    }
    
    private func bindSearchTerm() {
        $searchTerm
            .removeDuplicates()
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
    
    func playMusic() {
        guard let data = musicData else { return }
        Task {
            await GameAudioHelper.shared.startPlaying(data, option: .full)
        }
    }
    
    func stopMusic() {
        Task {
            await GameAudioHelper.shared.stopPlaying()
            GameAudioHelper.shared.stopEngine()
        }
    }
    
    func downloadArtwork(url: URL?) async -> Data? {
        guard let url else { return nil }
        return await dataDownloadRepository.downloadData(url: url)
    }
    
    func handleSelectedSong(with music: Music) {
        selectedMusic = music
        beginPlaying()
    }
  
    func submitMusic() async throws {
        if let selectedMusic {
            do {
                _ = try await answersRepository.submitMusic(answer: selectedMusic)
            } catch {
                ErrorHandler.handle(error)
                throw ASError.submitMusic
            }
        }
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
            throw ASError.searchMusicOnSelect
        }
    }

    @MainActor
    func randomMusic() async throws {
        do {
            let playlist = try await getPlaylist()
            guard let randomSongId = playlist.randomElement() else { return }
            selectedMusic = try await musicAPI.getSong(from: randomSongId)
        } catch {
            ErrorHandler.handle(error)
            throw ASError.randomMusic
        }
    }
    
    func getPlaylist() async throws -> [String] {
        guard let playlistURL = URL(string: "https://firebasestorage.googleapis.com/v0/b/alsongdalsong-boostcamp.firebasestorage.app/o/audios%2FselectMusicRandom%2FselectMusicPlayList.txt?alt=media&token=04fd9f51-7848-4e35-ace9-119be842ed55")
        else {
            Logger.debug("firebase로 부터 playlist url을 가져오지 못했습니다.")
            return []
        }
        guard let musicList = await dataDownloadRepository.downloadData(url: playlistURL) else {
            print("selectMusic: Emtpy playlist")
            return []
        }
            
        let musicListString = String(data: musicList, encoding: .utf8)!
        return musicListString.components(separatedBy: "\n").filter { !$0.isEmpty }
    }
    
    func downloadMusic(url: URL) {
        Task {
            guard let musicData = await dataDownloadRepository.downloadData(url: url) else {
                return
            }
            await updateMusicData(with: musicData)
        }
    }
    
    private func beginPlaying() {
        guard let url = selectedMusic?.previewUrl else { return }
        downloadMusic(url: url)
    }

    @MainActor
    func resetSearchList() {
        searchList = []
        currentPage = 0
        isAllLoaded = false
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
        cancellables.forEach { $0.cancel() }
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
