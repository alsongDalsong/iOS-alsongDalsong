import ASAudioKit
import Foundation

final class GameAudioHelper: Sendable {
    /// 플레이할 오디오 타입
    /// - bgm: 배경음악
    /// - effect: 버튼 클릭 등 효과음
    enum AudioType {
        case bgm, effect
    }
    
    /// 싱글톤
    /// 현재 볼륨 크기 대비 볼륨 설정 bgm 0.5, effectPlayer 0.5
    static let shared = GameAudioHelper()
    private init() {
        Task {
            await bgmPlayer.setVolume(0.5)
            await effectPlayer.setVolume(0.5)
        }
    }
    
    private let bgmPlayer = ASAudioPlayer()
    private let effectPlayer = ASAudioPlayer()
    
    func play(_ type: AudioType, name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        
        Task {
            let data = try Data(contentsOf: url)

            switch type {
            case .bgm: try await bgmPlayer.startPlaying(data: data)
            case .effect: try await effectPlayer.startPlaying(data: data)
            }
        }
    }
    
    func stop(_ type: AudioType) {
        Task {
            switch type {
            case .bgm: await bgmPlayer.stopPlaying()
            case .effect: await effectPlayer.stopPlaying()
            }
        }
    }
    
    func pause(_ type: AudioType) {
        Task {
            switch type {
            case .bgm: await bgmPlayer.pause()
            case .effect: await effectPlayer.pause()
            }
        }
    }
    
    func resume(_ type: AudioType) {
        Task {
            switch type {
            case .bgm: await bgmPlayer.resume()
            case .effect: await effectPlayer.resume()
            }
        }
    }
}
