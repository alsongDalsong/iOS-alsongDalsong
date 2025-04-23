import ASAudioKit
import Foundation

final class EffectAudioHelper: Sendable {
    /// 플레이할 오디오 타입
    /// - effect: 버튼 클릭 등 효과음
    
    /// 싱글톤
    /// 현재 볼륨 크기 대비 볼륨 설정 effectPlayer 0.5
    static let shared = EffectAudioHelper()
    private init() {
        Task {
            await effectPlayer.setVolume(0.5)
        }
    }
    
    private let effectPlayer = ASAudioPlayer()
    
    func play(name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        
        Task {
            let data = try Data(contentsOf: url)
            try await effectPlayer.startPlaying(data: data)
        }
    }
}
