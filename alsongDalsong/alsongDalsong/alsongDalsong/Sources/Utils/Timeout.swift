import Foundation

public struct TimeoutError: LocalizedError {
    public var errorDescription: String?

    init(_ description: String) {
        self.errorDescription = description
    }
}

public func withThrowingTimeout<T: Sendable>(
    seconds: TimeInterval,
    operation: @Sendable @escaping () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        group.addTask {
            try await Task.sleep(for: .seconds(seconds))
            throw TimeoutError.init("네트워크 요청이 너무 오래 걸립니다.")
        }
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}
