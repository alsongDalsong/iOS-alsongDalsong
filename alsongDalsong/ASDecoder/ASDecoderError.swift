import Foundation

enum ASDecoderError: LocalizedError {
    case decode

    var errorDescription: String? {
        switch self {
        case .decode: "디코딩 중 오류가 발생했습니다"
        }
    }
}
