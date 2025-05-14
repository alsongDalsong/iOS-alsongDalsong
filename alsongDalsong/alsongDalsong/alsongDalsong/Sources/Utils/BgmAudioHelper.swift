import ASAudioKit
import ASLogKit
import Combine
import Foundation

final class BgmAudioHelper: @unchecked Sendable {
    // MARK: - Singleton

    static let shared = BgmAudioHelper()
    private init() {}

    // MARK: - Private properties

    private var player: ASAudioPlayer?
    private var source: FileSource = .imported(.large)
    private var playType: PlayType = .full
    private var isConcurrent: Bool = false
    private var cancellable: AnyCancellable?

    var isMuted: Bool = false {
        didSet {
            Task {
                await player?.setVolume(isMuted ? 0 : volume)
            }
        }
    }

    var volume: Float = 1.0 {
        didSet {
            Task {
                await player?.setVolume(volume)
            }
        }
    }

    private var bgmDatas: [Bgm: Data] = [:]
    private var bgmState: Bgm = .onboarding {
        didSet {
            playBgm()
        }
    }

    private let queue = DispatchQueue(label: "alsongDalsong.AudioHelper")

    // MARK: - Publishers

    private let amplitudeSubject = PassthroughSubject<Float, Never>()
    private let playerStateSubject = PassthroughSubject<(FileSource, Bool), Never>()
    private let waveformUpdateSubject = PassthroughSubject<Int, Never>()
    private let recorderStateSubject = PassthroughSubject<Bool, Never>()
    private let recorderDataSubject = PassthroughSubject<Data, Never>()
    private let normalizedFrequencyAmplitudes = PassthroughSubject<[Float], Never>()
    private let playerEnginePrgress = PassthroughSubject<Double, Never>()
    var amplitudePublisher: AnyPublisher<Float, Never> {
        amplitudeSubject.eraseToAnyPublisher()
    }

    var playerStatePublisher: AnyPublisher<(FileSource, Bool), Never> {
        playerStateSubject.eraseToAnyPublisher()
    }

    var waveformUpdatePublisher: AnyPublisher<Int, Never> {
        waveformUpdateSubject.eraseToAnyPublisher()
    }

    var recorderStatePublisher: AnyPublisher<Bool, Never> {
        recorderStateSubject.eraseToAnyPublisher()
    }

    var recorderDataPublisher: AnyPublisher<Data, Never> {
        recorderDataSubject.eraseToAnyPublisher()
    }

    var normalizedFrequencyAmplitudesPublisher: AnyPublisher<[Float], Never> {
        normalizedFrequencyAmplitudes.eraseToAnyPublisher()
    }

    var playerEnginePrgressPublisher: AnyPublisher<Double, Never> {
        playerEnginePrgress.eraseToAnyPublisher()
    }

    var isPlaying: Bool {
        get async {
            guard let player else { return false }
            return await player.isPlaying()
        }
    }

    private func removePlayer() {
        Logger.debug(#function)
        player = nil
    }

    private func removeTimer() {
        Logger.debug(#function)
        cancellable?.cancel()
        cancellable = nil
    }
}

// MARK: - BGM

extension BgmAudioHelper {
    func playBgm() {
        Task {
            print(#function)
            await GameAudioHelper.shared.stopPlaying()
            GameAudioHelper.shared.stopEngine()
            await startPlaying(bgmDatas[bgmState], option: .loop, volume: volume)
        }
    }

    func addBgmData(name: Bgm, data: Data) {
        queue.async(flags: .barrier) {
            self.bgmDatas[name] = data
        }
    }

    func changeState(to newState: Bgm) {
        bgmState = newState
    }
}

// MARK: - Play Audio

extension BgmAudioHelper {
    /// 여러 조건을 적용해 오디오를 재생하는 함수
    /// - Parameters:
    ///   - file: 재생할 오디오 데이터
    ///   - source: 녹음 파일/url에서 가져온 파일
    ///   - playType: 전체 또는 부분 재생
    func startPlaying(_ file: Data?,
                      sourceType type: FileSource = .imported(.large),
                      option: PlayType = .full,
                      volume: Float = 1.0,
                      needsWaveUpdate: Bool = false) async
    {
        guard await checkPlayerState() else { return }
        guard let file else { return }

        sourceType(type)
        makePlayer()

        await player?.setOnPlaybackFinished { [weak self] in
            await self?.stopPlaying()
        }

        playerStateSubject.send((source, true))

        if needsWaveUpdate {
            updatePlayIndex()
        }

        await play(file: file, option: option, volume: volume)
    }

    private func play(file: Data, option: PlayType, volume: Float) async {
        switch option {
        case .full:
            do {
                try await player?.startPlaying(data: file)
            } catch {
                ErrorHandler.handle(error)
            }
        case let .partial(time):
            do {
                try await player?.startPlaying(data: file)
                try await Task.sleep(for: .seconds(time))
                await stopPlaying()
            } catch {
                ErrorHandler.handle(error)
            }
        case .loop:
            do {
                try await player?.startPlaying(data: file, fade: true, isLoop: true)
            } catch {
                ErrorHandler.handle(error)
            }
        @unknown default: break
        }
    }

    func stopPlaying() async {
        Logger.debug(#function)

        await player?.stopPlaying()

        removePlayer()
        removeTimer()

        playerStateSubject.send((source, false))
    }

    func pause() async {
        Task {
            await player?.pause()
        }
    }

    func resume() async {
        Task {
            await player?.resume()
        }
    }

    private func updatePlayIndex() {
        cancellable = Timer.publish(every: 0.25, on: .main, in: .common)
            .autoconnect()
            .scan(0) { count, _ in
                count + 1
            }
            .sink { [weak self] value in
                self?.waveformUpdateSubject.send(value - 1)
            }
    }

    private func makePlayer() {
        player = ASAudioPlayer()
    }

    private func checkPlayerState() async -> Bool {
        if await isPlaying {
            await player?.stopPlaying()
            removePlayer()
            playerStateSubject.send((source, false))
        }
        return true
    }
}

extension BgmAudioHelper {
    enum FileSource: Equatable {
        case imported(MusicPanelType)
        case recorded
    }
}

extension BgmAudioHelper {
    @discardableResult
    private func sourceType(_ type: FileSource) -> Self {
        source = type
        return self
    }

    @discardableResult
    func isConcurrent(_ isTrue: Bool) -> Self {
        isConcurrent = isTrue
        return self
    }
}

enum Bgm: String, CaseIterable {
    case onboarding
    case lobby
    case ingame
}
