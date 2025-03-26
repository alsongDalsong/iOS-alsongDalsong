import Foundation

public protocol ASFirebaseAuthProtocol: Sendable {
    func signIn(nickname: String, avatarURL: URL?) async throws
    func signOut() async throws
    func observeConnection() async throws
}
