import SwiftUI
import UIKit

enum MessageType {
    case music(MappedAnswer)
    case record(MappedRecord)

    var bubbleHeight: CGFloat {
        switch self {
            case .music:
                return 90
            case .record:
                return 64
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
        if alignment == .left {
            HStack(spacing: 12) {
                avatarView(info: playerInfo)
                speechBubble
            }
        }
        if alignment == .right {
            HStack(spacing: 12) {
                speechBubble
                avatarView(info: playerInfo)
            }
        }
    }

    @ViewBuilder
    private var speechBubble: some View {
        ZStack {
            contentView
                .padding(12)
                .frame(height: messageType.bubbleHeight)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(lineWidth: 3)
                        .foregroundStyle(.profileViewCircle)
                }
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.asSystem)
                        .shadow(color: .asShadow, radius: 2, y: 4)
                }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch messageType {
            case let .music(music):
                HStack {
                    artworkView(music)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    VStack(alignment: .leading) {
                        Text(music.title)
                            .foregroundStyle(.asForeground)

                        Text(music.artist)
                            .foregroundStyle(.gray)
                    }
                    .font(.wantedSansBold(size: 20))
                    .lineLimit(1)
                }
        case let .record(record):
            WaveFormWrapper(columns: record.recordAmplitudes, sampleCount: 24, circleColor: .asForeground, highlightColor: .asGreen)
        }
    }

    @ViewBuilder
    private func avatarView(info: PlayerInfo) -> some View {
        VStack {
            Image(uiImage: UIImage(data: info.playerAvatarData) ?? UIImage())
                .resizable()
                .background(Color.asMint)
                .aspectRatio(contentMode: .fill)
                .frame(width: 75, height: 75)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color.white, lineWidth: 5)
                )
                .padding(.bottom, 4)
            Text(info.playerName)
                .font(.doHyeon(size: 16))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 75)
    }

    @ViewBuilder
    private func artworkView(_ music: MappedAnswer) -> some View {
        Image(uiImage: UIImage(data: music.artworkData) ?? UIImage())
            .resizable()
            .aspectRatio(contentMode: .fill)
    }
}
