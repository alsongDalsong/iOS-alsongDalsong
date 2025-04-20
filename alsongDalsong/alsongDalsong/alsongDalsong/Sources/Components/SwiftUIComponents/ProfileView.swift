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
                .frame(width: 72, height: 72)
                .clipShape(Circle())
                .shadow(radius: 4, y: 8)
                .overlay(
                    Circle().stroke(Color.profileViewCircle, lineWidth: 5)
                )
                .overlay(alignment: .top) {
                    isHost ? Image(systemName: "crown.fill")
                        .foregroundStyle(.asYellow)
                        .font(.system(size: 20))
                        .offset(y: -20)
                        : nil
                }
                .padding(.bottom, 8)
            if let name {
                Text(name)
                    .foregroundStyle(isMyId ? .asBlue : .asForeground)
                    .font(.doHyeon(size: 16))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            } else {
                Text("비어 있음")
                    .font(.doHyeon(size: 16))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(width: 75)
    }
}
