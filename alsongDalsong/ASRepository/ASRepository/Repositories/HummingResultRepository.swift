import ASDecoder
import ASEncoder
import ASEntity
import ASNetworkKit
import ASRepositoryProtocol
import Combine
import Foundation

final class HummingResultRepository: HummingResultRepositoryProtocol {
    private var mainRepository: MainRepositoryProtocol
    private var networkManager: ASNetworkManagerProtocol

    init(
        mainRepository: MainRepositoryProtocol,
        networkManager: ASNetworkManagerProtocol
    ) {
        self.mainRepository = mainRepository
        self.networkManager = networkManager
    }

    func submitResult(isFinished: Bool) async throws -> Bool {
        do {
            let queryItems = [
                URLQueryItem(name: "userId", value: ASFirebaseAuth.myID),
                URLQueryItem(name: "roomNumber", value: mainRepository.number.value)
            ]
            let endPoint = FirebaseEndpoint(path: .submitResult, method: .post)
                .update(\.queryItems, with: queryItems)
                .update(\.headers, with: ["Content-Type": "application/json"])
            let body = try ASEncoder.encode(isFinished)
            let response = try await networkManager.sendRequest(to: endPoint, type: .json, body: body, option: .none)
            let responseDict = try ASDecoder.decode([String: String].self, from: response)
            return !responseDict.isEmpty
        } catch {
            throw ASRepositoryErrors(type: .submitResult, reason: error.localizedDescription, file: #file, line: #line)
        }
    }

    func getResultsCount() -> AnyPublisher<Int, Never> {
        mainRepository.results
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .map { $0.count }
            .eraseToAnyPublisher()
    }

    func getResult() ->
        AnyPublisher<[(
            answer: Answer,
            records: [ASEntity.Record],
            submit: Answer,
            recordOrder: UInt8
        )], Never>
    {
        Publishers.Zip4(mainRepository.answers, mainRepository.records, mainRepository.submits, mainRepository.recordOrder)
            .compactMap { answers, records, submits, recordOrder in
                answers?.map { answer in
                    let relatedRecords: [ASEntity.Record] = self.getRelatedRecords(for: answer,
                                                                                   from: records,
                                                                                   count: answers?.count ?? 0)
                    let relatedSubmit: Answer = self.getRelatedSubmit(for: answer, from: submits)

                    return (answer: answer, records: relatedRecords, submit: relatedSubmit, recordOrder: recordOrder ?? 0)
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    private func getRelatedRecords(for answer: Answer, from records: [ASEntity.Record]?, count: Int) -> [ASEntity.Record] {
        var filteredRecords: [ASEntity.Record] = []

        for i in 0 ..< count {
            let tempCheck: Int = (((answer.player?.order ?? 0) + i) % count)
            if let filteredRecord = records?.first(where: { record in
                (tempCheck == record.player?.order) &&
                    (record.recordOrder ?? 0 == i)
            }) {
                filteredRecords.append(filteredRecord)
            }
        }

        return filteredRecords
    }

    private func getRelatedSubmit(for answer: Answer, from submits: [Answer]?) -> Answer {
        let temp = (answer.player?.order ?? 0) - 1 + (submits?.count ?? 0)
        let targetOrder = temp % (submits?.isEmpty == true ? 1 : submits?.count ?? 1)

        let submit = submits?.first(where: { submit in
            targetOrder == submit.player?.order
        })

        // TODO: nil 값에 대한 처리 필요
        return submit ?? Answer.answerStub1
    }
}
