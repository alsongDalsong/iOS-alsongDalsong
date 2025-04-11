import ASEntity
import SwiftUI

struct LobbyView: View {
    @ObservedObject var viewModel: LobbyViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(0..<viewModel.playerMaxCount, id: \.self) { index in
                        if index < viewModel.players.count {
                            let player = viewModel.players[index]
                            if viewModel.isHost, player.id != viewModel.host?.id {
                                Button {
                                    presentKickAlert(player: player)
                                } label: {
                                    ProfileView(
                                        imagePublisher: { url in
                                            await viewModel.getAvatarData(url: url)
                                        },
                                        name: player.nickname,
                                        isMyId: player.id == viewModel.myId,
                                        isHost: player.id == viewModel.host?.id,
                                        imageUrl: player.avatarUrl
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                ProfileView(
                                    imagePublisher: { url in
                                        await viewModel.getAvatarData(url: url)
                                    },
                                    name: player.nickname,
                                    isMyId: player.id == viewModel.myId,
                                    isHost: player.id == viewModel.host?.id,
                                    imageUrl: player.avatarUrl
                                )
                            }
                        } else {
                            ProfileView(
                                imagePublisher: { url in
                                    await viewModel.getAvatarData(url: url)
                                },
                                name: nil,
                                isMyId: false,
                                isHost: false,
                                imageUrl: nil
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)
            VStack {
                if viewModel.isHost {
                    GeometryReader { reader in
                        SnapperView(size: reader.size, currentMode: $viewModel.mode)
                    }
                } else {
                    GeometryReader { geometry in
                        ModeView(viewModel: ModeViewModel(mode: viewModel.mode),width: geometry.size.width * 0.85)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
        .background(Color.asBackground)
    }

    func presentKickAlert(player: Player) {
        let alertContrller = DefaultAlertController(
            titleText: .kick(playerName: player.nickname ?? ""),
            primaryButtonText: .kick,
            secondaryButtonText: .cancel,
            primaryButtonAction: { _ in
                Task {
                    try await viewModel.kickUser(userID: player.id)
                }
            }
        )
        if let topVC = UIApplication.shared.topViewController(), topVC is LobbyViewController {
            topVC.presentAlert(alertContrller)
        }
    }
}
