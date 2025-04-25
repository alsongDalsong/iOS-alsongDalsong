import ASEntity
import SwiftUI

struct ASMusicItemCell: View {
    @State private var artworkData: Data?
    let music: Music?
    let fetchArtwork: (URL?) async -> Data?

    var body: some View {
        HStack {
            if let artworkData, let uiImage = UIImage(data: artworkData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: .responsiveWidth(60), height: .responsiveHeight(60))
                    .clipShape(RoundedRectangle(cornerRadius: .responsiveWidth(4)))
                    .padding(.horizontal, .responsiveWidth(8))
            } else if let music, let artworkColor = music.artworkBackgroundColor {
                Rectangle()
                    .foregroundColor(Color(hex: artworkColor))
                    .frame(width: .responsiveWidth(60), height: .responsiveHeight(60))
                    .clipShape(RoundedRectangle(cornerRadius: .responsiveWidth(4)))
                    .padding(.horizontal, .responsiveWidth(8))
            } else {
                Image(systemName: "music.quarternote.3")
                    .frame(width: .responsiveWidth(60), height: .responsiveHeight(60))
                    .background(.asSystem)
                    .clipShape(RoundedRectangle(cornerRadius: .responsiveWidth(4)))
                    .padding(.horizontal, .responsiveWidth(8))
            }
            VStack(alignment: .leading) {
                Text(music?.title ?? String(localized: "선택된 곡 없음"))
                    .font(.wantedSansBold(size: .responsiveHeight(16)))
                    .lineLimit(1)
                Text(music?.artist ?? String(localized: "아티스트"))
                    .foregroundStyle(.gray)
                    .font(.wantedSansBold(size: .responsiveHeight(16)))
                    .lineLimit(1)
            }
        }
        .task(id: music) {
            artworkData = nil
            if let music {
                artworkData = await fetchArtwork(music.artworkUrl)
            }
        }
    }
}

#Preview {
    ASMusicItemCell(music: Music()) { _ in nil }
}
