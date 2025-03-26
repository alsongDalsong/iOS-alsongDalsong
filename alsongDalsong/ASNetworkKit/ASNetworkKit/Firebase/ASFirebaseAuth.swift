import ASEncoder
import ASEntity
import ASLogKit
import Foundation
@preconcurrency internal import FirebaseAuth
@preconcurrency internal import FirebaseDatabase

public final class ASFirebaseAuth: ASFirebaseAuthProtocol {
    public static var myID: String?
    private let databaseRef = Database.database().reference()

    public func signIn(nickname: String, avatarURL: URL?) async throws {
        do {
            guard let myID = ASFirebaseAuth.myID else {
                throw ASNetworkError.firebaseSignIn
            }
            let player = Player(id: myID, avatarUrl: avatarURL, nickname: nickname, order: 0)
            let playerData = try ASEncoder.encode(player)
            let dict = try JSONSerialization.jsonObject(with: playerData, options: .allowFragments) as? [String: Any]
            let userStatusRef = databaseRef.child("players").child(myID)
            userStatusRef.keepSynced(true)
            let connectedRef = databaseRef.child(".info/connected")
            connectedRef.observe(.value) { snapshot in
                guard let isConnected = snapshot.value as? Bool else { return }
                if isConnected {
                    userStatusRef.setValue(dict)
                }
            }
        } catch {
            ErrorHandler.handle(error)
            throw ASNetworkError.firebaseSignIn
        }
    }

    public func signOut() async throws {
        do {
            guard let userID = ASFirebaseAuth.myID else {
                throw ASNetworkError.firebaseSignOut
            }
            try await databaseRef.child("players").child(userID).removeValue()
            try Auth.auth().signOut()
        } catch {
            ErrorHandler.handle(error)
            throw ASNetworkError.firebaseSignOut
        }
    }

    public func observeConnection() async throws {
        do {
            guard let userID = ASFirebaseAuth.myID else {
                throw ASNetworkErrors(type: .firebaseSignOut, reason: "ASFirebaseAuth.myID is nil", file: #file, line: #line)
            }
            try await databaseRef.child("players").child(userID).onDisconnectRemoveValue()
            try Auth.auth().signOut()
        } catch {
            // TODO: - error message
            throw error
        }
    }

    public static func configure() {
        if let uid = Auth.auth().currentUser?.uid {
            ASFirebaseAuth.myID = uid
        } else {
            Task {
                let authResult = try await Auth.auth().signInAnonymously()
                ASFirebaseAuth.myID = authResult.user.uid
            }
        }
    }
}
