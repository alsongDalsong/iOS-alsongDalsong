import ASEntity
import Foundation

public protocol ASFirebaseStorageProtocol {
    /// 플레이어 아바타 이미지 URL들을 가져오는 함수.
    func getAvatarUrls() async throws -> [AvatarPair]
    /// 배경음악 m4a 파일의 URL을 가져오는 함수
    func getBgmUrl(for path: String) async throws -> URL?
}
