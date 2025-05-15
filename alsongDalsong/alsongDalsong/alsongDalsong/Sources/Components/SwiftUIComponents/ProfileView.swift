import Foundation
import SwiftUI

struct AsyncImageView: View {
    let imagePublisher: (URL?) async -> Data?
    let url: URL?
    @State private var imageData: Data?

    var body: some View {
        Group {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .transition(.move(edge: .bottom))
            } else {
                Circle()
                    .fill(.clear)
            }
        }
        .animation(.linear(duration: 0.5), value: imageData)
        .onAppear {
            Task {
                imageData = await imagePublisher(url)
            }
        }
    }
}

struct ProfileView: View {
    let imagePublisher: (URL?) async -> Data?
    let name: String?
    let isMyId: Bool
    let isHost: Bool
    let imageUrl: URL?

    var body: some View {
        VStack {
            AsyncImageView(imagePublisher: imagePublisher, url: imageUrl)
                .background(Color.profileViewBackground)
                .frame(width: .responsiveWidth(72), height: .responsiveHeight(72))
                .clipShape(Circle())
                .shadow(radius: .responsiveWidth(4), y: .responsiveHeight(8))
                .overlay(
                    Circle().stroke(Color.profileViewCircle, lineWidth: .responsiveWidth(5))
                )
                .overlay(alignment: .top) {
                    isHost ? Image(systemName: "crown.fill")
                        .foregroundStyle(.asYellow)
                        .font(.system(size: .responsiveHeight(20)))
                        .offset(y: .responsiveHeight(-20))
                        : nil
                }
                .padding(.bottom, 8)
            if let name {
                Text(name)
                    .frame(height: .responsiveHeight(38), alignment: .top)
                    .foregroundStyle(isMyId ? .asBlue : .asForeground)
                    .font(.doHyeon(size: .responsiveHeight(16)))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("비어 있음")
                    .frame(height: .responsiveHeight(38), alignment: .top)
                    .font(.doHyeon(size: .responsiveHeight(16)))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(width: .responsiveWidth(75))
    }
}
