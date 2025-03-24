import Foundation

enum ASRepositoryError: LocalizedError {
    case submitMusic
    case getAvatarUrls
    case postRecording, postResetGame
    case uploadRecording
    case createRoom, joinRoom, leaveRoom, startGame, changeMode, changeRecordOrder, resetGame, kickUser, sendRequest
    case submitAnswer

    var errorDescription: String? {
        switch self {
            case .submitMusic: "음악 제출 중 오류가 발생했습니다"
            case .getAvatarUrls: "아바타 URL을 가져오는 중 오류가 발생했습니다"
            case .postRecording: "녹음을 업로드하는 중 오류가 발생했습니다"
            case .postResetGame: "게임 초기화 요청 중 오류가 발생했습니다"
            case .uploadRecording: "녹음 파일을 업로드하는 중 오류가 발생했습니다"
            case .createRoom: "방을 생성하는 중 오류가 발생했습니다"
            case .joinRoom: "방에 참가하는 중 오류가 발생했습니다"
            case .leaveRoom: "방을 떠나는 중 오류가 발생했습니다"
            case .startGame: "게임을 시작하는 중 오류가 발생했습니다"
            case .changeMode: "게임 모드를 변경하는 중 오류가 발생했습니다"
            case .changeRecordOrder: "녹음 순서를 변경하는 중 오류가 발생했습니다"
            case .resetGame: "게임을 초기화하는 중 오류가 발생했습니다"
            case .sendRequest: "요청을 보내는 중 오류가 발생했습니다"
            case .kickUser: "유저를 추방하는 중 오류가 발생했습니다"
            case .submitAnswer: "정답을 제출하는 중 오류가 발생했습니다"
        }
    }
}
