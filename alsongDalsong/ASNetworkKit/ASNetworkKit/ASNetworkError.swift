import Foundation

public enum ASNetworkError: LocalizedError {
    case statusError(description: String)
    case urlError
    case getAvatarUrls
    case firebaseSignIn
    case firebaseSignOut
    case firebaseObserveConnection
    case firebaseListener
    case decode
    case responseError

    public var errorDescription: String? {
        switch self {
        case .statusError(let description): "\(description)"
        case .urlError: "잘못된 URL 요청입니다"
        case .getAvatarUrls: "아바타 URL을 가져오는 중 오류가 발생했습니다"
        case .firebaseSignIn: "Firebase 로그인 중 오류가 발생했습니다"
        case .firebaseSignOut: "Firebase 로그아웃 중 오류가 발생했습니다"
        case .firebaseObserveConnection: "Firebase 연결 상태 감시 중 오류가 발생했습니다"
        case .firebaseListener, .decode: "Firebase 리스너에서 오류가 발생했습니다"
        case .responseError: "네트워크 응답 오류가 발생했습니다"
        }
    }
}
