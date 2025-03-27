import Foundation

enum ASAudioError: LocalizedError {
    case analyzeAudio
    case startPlaying, getDuration
    case configureAudioSession
    case startRecording

    var errorDescription: String? {
        switch self {
            case .analyzeAudio: "오디오 분석 중 오류가 발생했습니다"
            case .startPlaying: "오디오 재생을 시작하는 중 오류가 발생했습니다"
            case .getDuration: "오디오 길이를 가져오는 중 오류가 발생했습니다"
            case .configureAudioSession: "오디오 세션을 설정하는 중 오류가 발생했습니다"
            case .startRecording: "오디오 녹음을 시작하는 중 오류가 발생했습니다"
        }
    }
}
