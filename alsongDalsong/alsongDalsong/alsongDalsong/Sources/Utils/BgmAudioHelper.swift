import ASAudioKit
import ASLogKit
import AVFoundation
import Combine
import Foundation

final class BgmAudioHelper: @unchecked Sendable {
    // MARK: - Singleton

    static let shared = BgmAudioHelper()
    private init() {
        do {
            try configureAudioSession()
        } catch {}
    }

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

    private func configureAudioSession() throws {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            // TODO: 세션 설정 실패에 따른 처리
            ErrorHandler.handle(error)
        }
    }
}

// MARK: - BGM

extension BgmAudioHelper {
    func playBgm() {
        Task {
            print(#function)
            await startPlaying(bgmDatas[bgmState], volume: volume)
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
    func startPlaying(_ file: Data?,
                      sourceType type: FileSource = .imported(.large),
                      volume: Float = 1.0,
                      needsWaveUpdate: Bool = false) async
    {
        guard let file else { return }

        sourceType(type)
        makePlayer()

        await player?.setOnPlaybackFinished { [weak self] in
            await self?.stopPlaying()
        }
        await play(file: file, volume: volume)
    }

    private func play(file: Data, volume: Float) async {
        do {
            try await player?.startPlaying(data: file, fade: true, isLoop: true)
        } catch {
            ErrorHandler.handle(error)
        }
    }

    func stopPlaying() async {
        Logger.debug(#function)

        await player?.stopPlaying()

        removePlayer()
        removeTimer()
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

    private func makePlayer() {
        player = ASAudioPlayer()
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
}

enum Bgm: String, CaseIterable {
    case onboarding
    case lobby
    case ingame
}
