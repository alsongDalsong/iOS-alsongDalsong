public enum Mode: String, Codable, CaseIterable, Identifiable, CustomStringConvertible {
    case humming
    case harmony
    case sync
    case instant
    case tts

    public var id: String { rawValue }

    public var Index: Int {
        switch self {
            case .humming: 1
            case .harmony: 2
            case .sync: 3
            case .instant: 4
            case .tts: 5
        }
    }

    public static func fromIndex(_ index: Int) -> Mode? {
        switch index {
            case 1: return .humming
            case 2: return .harmony
            case 3: return .sync
            case 4: return .instant
            case 5: return .tts
            default: return nil
        }
    }

    public var title: String {
        switch self {
            case .humming: return "허밍"
            case .harmony: return "하모니"
            case .sync: return "이구동성"
            case .instant: return "찰나의 순간"
            case .tts: return "TTS"
        }
    }

    public var duration: String {
        switch self {
            case .humming:
                "5~10분"
            case .harmony:
                "5~10분"
            case .sync:
                "5~10분"
            case .instant:
                "5~10분"
            case .tts:
                "5~10분"
        }
    }

    public var recommendedPlayers: String {
        switch self {
            case .humming:
                "3~6인"
            case .harmony:
                "2~6인"
            case .sync:
                "4~6인"
            case .instant:
                "1~6인"
            case .tts:
                "2~6인"
        }
    }

    public var summary: String {
        switch self {
            case .humming:
                "허밍으로 노래를 전달하자!"
            case .harmony:
                "노래의 화음을 쌓아보자!"
            case .sync:
                "동시에 섞인 노래를 맞춰보자!"
            case .instant:
                "아주 잠깐 듣고 무슨노래인지 맞춰보자!"
            case .tts:
                "가사만 보고 노래를 맞춰보자!"
        }
    }

    public var description: String {
        switch self {
        case .humming:
            """
            노래를 선택하고 허밍으로 시작하세요!  
            다음 사람은 따라 부르고, 마지막은 정답을 맞춰야 해요.
            """
        case .harmony:
            """
            각자 파트를 녹음해 하모니를 완성하세요!
            누구의 파트가 가장 어울릴까요?
            """
        case .sync:
            """
            모두가 동시에 노래를 부르며 정답을 맞추는 협동 모드!
            목소리가 하나로 어우러질 때, 과연 정답은?
            """
        case .instant:
            """
            1초짜리 음악 클립을 듣고 바로 맞추는 집중력 테스트!
            짧은 순간, 당신의 기억력을 믿어보세요.
            """
        case .tts:
            """
            노래 가사만 듣고 어떤 곡인지 맞춰보세요.
            가사만으로 떠오르는 그 노래, 기억해낼 수 있을까요?
            """
        }
    }

    public var imageName: String {
        switch self {
            case .humming: return "humming"
            case .harmony: return "harmony"
            case .sync: return "sync"
            case .instant: return "instant"
            case .tts: return "tts"
        }
    }
}
