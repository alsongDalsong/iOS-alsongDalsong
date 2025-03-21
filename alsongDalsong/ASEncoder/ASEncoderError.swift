import Foundation

enum ASEncoderError: LocalizedError {
    case encode

    var errorDescription: String? {
        switch self {
        case .encode: "인코딩 중 오류가 발생했습니다"
        }
    }
}
