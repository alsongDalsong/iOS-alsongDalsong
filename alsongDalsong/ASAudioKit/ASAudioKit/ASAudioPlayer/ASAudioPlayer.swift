import ASLogKit
import AVFoundation

public enum PlayType: Sendable {
    case full
    case partial(time: Int)
}

public actor ASAudioPlayer: NSObject {
    private var audioPlayer: AVAudioPlayer?

    override public init() {}

    public var onPlaybackFinished: (@Sendable () async -> Void)?

    /// 볼륨 크기를 지정합니다.
    public func setVolume(_ volume: Float) {
        audioPlayer?.volume = volume
    }

    /// 녹음파일을 재생하고 옵션에 따라 재생시간을 설정합니다.
    public func startPlaying(data: Data, option: PlayType = .full, fade: Bool = false, isLoop: Bool = false) throws {
        do {
            try configureAudioSession()
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.setVolume(audioPlayer?.volume ?? 1.0, fadeDuration: fade ? 2.0 : 0)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.isMeteringEnabled = true
            audioPlayer?.numberOfLoops = isLoop ? -1 : 0
        } catch {
            // TODO: 오디오 객체생성 실패 시 처리
            ErrorHandler.handle(error)
            throw ASAudioError.startPlaying
        }

        switch option {
        case .full:
            audioPlayer?.play()
        case let .partial(time):
            audioPlayer?.currentTime = 0
            audioPlayer?.play()
            DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(time)) {
                Task {
                    await self.stopPlaying()
                }
            }
        }
    }

    public func stopPlaying() {
        audioPlayer?.stop()
    }

    public func pause() {
        audioPlayer?.pause()
    }

    public func resume() {
        guard let player = audioPlayer else { return }

        if !player.isPlaying {
            player.play()
        }
    }

    /// AVPlayer객체의 재생여부를 확인합니다.
    public func isPlaying() -> Bool {
        if let audioPlayer {
            return audioPlayer.isPlaying
        }
        return false
    }

    /// 녹음파일의 총 녹음시간을 리턴합니다.
    public func getDuration(data: Data) throws -> TimeInterval {
        if audioPlayer == nil {
            do {
                audioPlayer = try AVAudioPlayer(data: data)
            } catch {
                // TODO: 오디오 객체생성 실패 시 처리
                ErrorHandler.handle(error)
                throw ASAudioError.getDuration
            }
        }
        return audioPlayer?.duration ?? 0
    }

    public func setOnPlaybackFinished(_ handler: @Sendable @escaping () async -> Void) {
        onPlaybackFinished = handler
    }

    private func configureAudioSession() throws {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            // TODO: 세션 설정 실패에 따른 처리
            ErrorHandler.handle(error)
            throw ASAudioError.configureAudioSession
        }
    }
}

extension ASAudioPlayer: @preconcurrency AVAudioPlayerDelegate {
    @MainActor
    public func audioPlayerDidFinishPlaying(_: AVAudioPlayer, successfully _: Bool) {
        Task {
            await onPlaybackFinished?()
        }
    }
}
