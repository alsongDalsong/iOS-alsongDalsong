import Foundation

enum ASError: LocalizedError {
    case submitHumming
    case gameStart, kickUser
    case joinRoom(description: String), createRoom
    case submitRehumming
    case changeRecordOrder, navigateToLobby
    case submitMusic, searchMusicOnSelect, randomMusic
    case searchMusicOnSubmit, submitAnswer

    var errorDescription: String? {
        switch self {
            case .submitHumming: "허밍을 제출하는 중 오류가 발생했습니다"
            case .gameStart: "게임 시작 중 오류가 발생했습니다"
            case .kickUser: "유저를 강퇴하는 중 오류가 발생했습니다"
            case .joinRoom(let description): "\(description)"
            case .createRoom: "방을 생성하는 중 오류가 발생했습니다"
            case .submitRehumming: "재허밍을 제출하는 중 오류가 발생했습니다"
            case .changeRecordOrder: "녹음 순서를 변경하는 중 오류가 발생했습니다"
            case .navigateToLobby: "로비로 이동하는 중 오류가 발생했습니다"
            case .submitMusic: "음악을 제출하는 중 오류가 발생했습니다"
            case .searchMusicOnSelect: "음악 선택 중 검색 오류가 발생했습니다"
            case .randomMusic: "랜덤 음악을 가져오는 중 오류가 발생했습니다"
            case .searchMusicOnSubmit: "음악 제출 시 검색 오류가 발생했습니다"
            case .submitAnswer: "정답을 제출하는 중 오류가 발생했습니다"
        }
    }
}
