import SwiftUI
import UIKit

@MainActor
enum MessageType {
    case music(MappedAnswer)
    case record(MappedRecord)

    var bubbleHeight: CGFloat {
        switch self {
            case .music:
                return .responsiveHeight(90)
            case .record:
                return .responsiveHeight(64)
        }
    }
}

enum MessageAlignment {
    case left
    case right
}

struct SpeechBubbleCell: View {
    let row: Int
    let messageType: MessageType
    private var alignment: MessageAlignment {
        row.isMultiple(of: 2) ? .left : .right
    }

    private var playerInfo: PlayerInfo {
        switch messageType {
            case let .music(music): return music
            case let .record(record): return record
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: .responsiveWidth(12)) {
            if alignment == .left {
                speechBubble
            }
            
            avatarView(info: playerInfo)
            
            if alignment == .right {
                speechBubble
            }
        }
    }

    @ViewBuilder
    private var speechBubble: some View {
        ZStack {
            contentView
                .padding(.responsiveWidth(12))
                .frame(height: .responsiveHeight(messageType.bubbleHeight))
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch messageType {
            case let .music(music):
                MediumAudioPlayerWrapper(mappedAnswer: music)
            case let .record(record):
                WaveFormWrapper(
                    columns: record.recordAmplitudes,
                    sampleCount: 24,
                    circleColor: .profileViewCircle,
                    highlightColor: .asForeground
                )
                .background {
                    RoundedRectangle(cornerRadius: .responsiveWidth(12), style: .continuous)
                        .stroke(lineWidth: .responsiveWidth(4))
                        .foregroundStyle(.profileViewCircle)
                }
                .background {
                    RoundedRectangle(cornerRadius: .responsiveWidth(12), style: .continuous)
                        .fill(.asSystem)
                        .shadow(color: .asShadow, radius: .responsiveWidth(2), y: .responsiveHeight(4))
                }
        }
    }

    @ViewBuilder
    private func avatarView(info: PlayerInfo) -> some View {
        VStack {
            Image(uiImage: UIImage(data: info.playerAvatarData) ?? UIImage())
                .resizable()
                .background(Color.profileViewBackground)
                .aspectRatio(contentMode: .fill)
                .frame(width: .responsiveWidth(75), height: .responsiveHeight(75))
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color.profileViewCircle, lineWidth: .responsiveWidth(5))
                )
                .padding(.bottom, .responsiveHeight(4))
            Text(info.playerName)
                .font(.doHyeon(size: .responsiveHeight(16)))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: .responsiveWidth(75))
    }

    @ViewBuilder
    private func artworkView(_ music: MappedAnswer) -> some View {
        Image(uiImage: UIImage(data: music.artworkData) ?? UIImage())
            .resizable()
            .aspectRatio(contentMode: .fill)
    }
}
