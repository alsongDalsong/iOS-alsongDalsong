import Foundation

enum ASMusicError: LocalizedError {
    case notAuthorized
    case search
    case playListHasNoSongs

    var errorDescription: String? {
        switch self {
        case .notAuthorized: "음악 서비스를 사용할 권한이 없습니다"
        case .search: "음악 검색 중 오류가 발생했습니다"
        case .playListHasNoSongs: "재생 목록에 노래가 없습니다"
        }
    }
}
