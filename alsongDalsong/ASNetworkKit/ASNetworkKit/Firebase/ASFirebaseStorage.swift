@preconcurrency internal import FirebaseStorage
import ASEntity
import ASLogKit
import Foundation

final class ASFirebaseStorage: ASFirebaseStorageProtocol {
    private let storageRef = Storage.storage().reference()
    
    func getAvatarUrls() async throws -> [AvatarPair] {
        let onboardingAvatarRef = storageRef.child("avatar")
        let lobbyAvatarRef = storageRef.child("avatar").child("Lobby")
        do {
            let onboardingResult = try await onboardingAvatarRef.listAll()
            let lobbyResult = try await lobbyAvatarRef.listAll()
            
            let onboardingUrls = try await fetchDownloadURLs(from: onboardingResult.items)
            let lobbyUrls = try await fetchDownloadURLs(from: lobbyResult.items)
            
            let onboardingDict: [Int: URL] = Dictionary(uniqueKeysWithValues:
                onboardingUrls.compactMap { url in
                    guard let number = extractFileNumber(from: url) else { return nil }
                    return (number, url)
                }
            )
            let lobbyDict: [Int: URL] = Dictionary(uniqueKeysWithValues:
                lobbyUrls.compactMap { url in
                    guard let number = extractFileNumber(from: url) else { return nil }
                    return (number, url)
                }
            )
            
            let pairs: [AvatarPair] = onboardingDict.compactMap { key, onboardingURL in
                guard let lobbyURL = lobbyDict[key] else { return nil }
                return AvatarPair(onboarding: onboardingURL, lobby: lobbyURL)
            }

            return pairs
            
        } catch {
            ErrorHandler.handle(error)
            throw ASNetworkError.getAvatarUrls
        }
    }
    
    private func fetchDownloadURLs(from items: [StorageReference]) async throws -> [URL] {
        try await withThrowingTaskGroup(of: URL.self) { taskGroup in
            for item in items {
                taskGroup.addTask {
                    try await item.downloadURL()
                }
            }
            
            return try await taskGroup.reduce(into: []) { urls, url in
                urls.append(url)
            }
        }
    }
    
    private func extractFileNumber(from url: URL) -> Int? {
        let filename = url.lastPathComponent
        let baseFilename = filename.split(separator: "?").first ?? ""
        let numberString = baseFilename.split(separator: ".").first ?? ""
        return Int(numberString)
    }
}
