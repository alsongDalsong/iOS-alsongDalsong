import ASContainer
import ASEntity
import ASLogKit
import ASRepositoryProtocol
import Combine
import UIKit

@MainActor
final class GameNavigationController: @unchecked Sendable {
    let navigationController: UINavigationController
    private let gameStateRepository: GameStateRepositoryProtocol
    private let roomActionRepository: RoomActionRepositoryProtocol
    private var subscriptions: Set<AnyCancellable> = []
    private let roomNumber: String
    private var roomPlayersNumber: Int = 0

    private var gameInfo: GameState? {
        didSet {
            guard let gameInfo else { return }
            updateViewControllers(state: gameInfo)
        }
    }

    init(navigationController: UINavigationController,
         gameStateRepository: GameStateRepositoryProtocol,
         roomActionRepository: RoomActionRepositoryProtocol,
         roomNumber: String)
    {
        self.navigationController = navigationController
        self.gameStateRepository = gameStateRepository
        self.roomActionRepository = roomActionRepository
        self.roomNumber = roomNumber
    }

    func setConfiguration() {
        gameStateRepository.getGameState()
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] gameState in
                self?.gameInfo = gameState
            }
            .store(in: &subscriptions)

        gameStateRepository.receiveKickOut()
            .receive(on: DispatchQueue.main)
            .filter { $0 }
            .sink { [weak self] _ in
                self?.leaveRoom()
                let alert = SingleButtonAlertController(
                    titleText: .receiveKick)
                { _ in
                    self?.navigationController.popToRootViewController(animated: true)
                    self?.navigationController.navigationBar.isHidden = true
                }
                self?.navigationController.presentAlert(alert)
            }
            .store(in: &subscriptions)

        gameStateRepository.getPlayersCount()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] playersCount in
                guard let gameInfo = self?.gameInfo else { return }
                let viewType = gameInfo.resolveViewType()
                if viewType != .lobby, playersCount != self?.roomPlayersNumber {
                    self?.leaveRoom()
                    self?.showNotPlayable()
                } else if viewType == .lobby {
                    self?.roomPlayersNumber = playersCount
                }
            }
            .store(in: &subscriptions)
    }

    private func setupNavigationBar(for viewController: UIViewController) {
        navigationController.navigationBar.isHidden = false
        navigationController.navigationBar.tintColor = .asForeground
        let fontStyle = setFont()
        navigationController.navigationBar.titleTextAttributes = [.font: fontStyle]

        let backButtonAction = UIAction { [weak self] _ in
            let alert = DefaultAlertController(
                titleText: .leaveRoom,
                primaryButtonText: .leave,
                secondaryButtonText: .cancel
            ) { [weak self] _ in
                self?.leaveRoom()
                self?.navigationController.popToRootViewController(animated: true)
                self?.navigationController.navigationBar.isHidden = true
                print("나가기")
                BgmAudioHelper.shared.changeState(to: .onboarding)
            }
            self?.navigationController.presentAlert(alert)
        }

        let backButton = ASButton()
        backButton.setConfiguration(
            systemImageName: "arrowshape.backward.fill",
            imageSize: .responsiveWidth(12),
            backgroundColor: .backButtonBackground,
            cornerStyle: .large,
            baseForegroundColor: .backButtonForeground,
            shadowColor: .buttonShadowWithLine,
            shadowHeight: .responsiveHeight(4),
            strokeColor: .buttonShadowWithLine,
            strokeWidth: .responsiveWidth(3)
        )
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addAction(backButtonAction, for: .touchUpInside)

        let settingButtonAction = UIAction { [weak self] _ in
            let settingViewController = SettingViewController()
            settingViewController.modalTransitionStyle = .crossDissolve
            settingViewController.modalPresentationStyle = .overFullScreen
            self?.navigationController.present(settingViewController, animated: true, completion: nil)
        }

        let settingButton = ASButton()
        settingButton.setConfiguration(
            systemImageName: "gear",
            imageSize: .responsiveWidth(16),
            backgroundColor: .inviteButton,
            cornerStyle: .large,
            baseForegroundColor: .white,
            shadowColor: .buttonShadowOfDefault,
            shadowHeight: .responsiveHeight(4)
        )
        settingButton.translatesAutoresizingMaskIntoConstraints = false
        settingButton.addAction(settingButtonAction, for: .touchUpInside)

        NSLayoutConstraint.activate([
            backButton.widthAnchor.constraint(equalToConstant: .responsiveWidth(32)),
            backButton.heightAnchor.constraint(equalToConstant: .responsiveHeight(32)),

            settingButton.widthAnchor.constraint(equalToConstant: .responsiveWidth(32)),
            settingButton.heightAnchor.constraint(equalToConstant: .responsiveHeight(32)),

        ])

        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        viewController.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: settingButton)
        viewController.title = setTitle()
    }

    private func setTitle() -> String {
        guard let gameInfo else { return "" }
        let viewType = gameInfo.resolveViewType()
        switch viewType {
            case .submitMusic:
                return String(localized: "노래 선택")
            case .humming:
                return String(localized: "허밍")
            case .rehumming:
                guard let recordOrder = gameInfo.recordOrder else { return "" }
                let maxRehummingRounds = gameInfo.players.count <= 3 ? 1 : 2
                return String(localized: "리허밍") + "\(recordOrder)/\(maxRehummingRounds)"
            case .submitAnswer:
                return String(localized: "정답 맞추기")
            case .result:
                guard let recordOrder = gameInfo.recordOrder else { return "" }
                let playerCount = gameInfo.players.count
                let baseResult: UInt8 = (playerCount == 2) ? 0 : (playerCount == 3 ? 1 : 2)
                let currentRound = recordOrder - baseResult
                return String(localized: "결과 확인") + " \(currentRound)/\(playerCount)"
            case .lobby:
                return "#\(roomNumber)"
            default:
                return ""
        }
    }

    private func setFont() -> UIFont {
        return .font(.dohyeon, forTextStyle: .headline)
    }

    private func updateViewControllers(state: GameState) {
        guard let viewType = state.resolveViewType() else {
            return
        }
        
        switch viewType {
        case .submitMusic: navigateToSelectMusic()
        case .humming: navigateToHumming()
        case .rehumming: navigateToRehumming()
        case .submitAnswer: navigateToSubmitAnswer()
        case .result: navigateToResult()
        case .lobby: navigateToLobby()
        default: break
        }
        
        if viewType != .lobby {
            Task {
                BgmAudioHelper.shared.changeState(to: .ingame)
            }
        }
        
        if viewType == .lobby {
            BgmAudioHelper.shared.changeState(to: .lobby)
        }
    }

    private func navigateToLobby() {
        if navigationController.topViewController is LobbyViewController {
            return
        }

        if let vc = navigationController.viewControllers.first(where: { $0 is LobbyViewController }) {
            navigationController.popToViewController(vc, animated: true)
            return
        }

        let roomInfoRepository: RoomInfoRepositoryProtocol = DIContainer.shared.resolve(RoomInfoRepositoryProtocol.self)
        let playersRepository: PlayersRepositoryProtocol = DIContainer.shared.resolve(PlayersRepositoryProtocol.self)
        let roomActionRepository: RoomActionRepositoryProtocol = DIContainer.shared.resolve(RoomActionRepositoryProtocol.self)
        let dataDownloadRepository: DataDownloadRepositoryProtocol = DIContainer.shared.resolve(DataDownloadRepositoryProtocol.self)

        let vm = LobbyViewModel(
            playersRepository: playersRepository,
            roomInfoRepository: roomInfoRepository,
            roomActionRepository: roomActionRepository,
            dataDownloadRepository: dataDownloadRepository
        )
        let vc = LobbyViewController(lobbyViewModel: vm)
        setupNavigationBar(for: vc)
        navigationController.pushViewController(vc, animated: true)
    }

    private func navigateToSelectMusic() {
        let playersRepository = DIContainer.shared.resolve(PlayersRepositoryProtocol.self)
        let answersRepository = DIContainer.shared.resolve(AnswersRepositoryProtocol.self)
        let gameStatusRepository = DIContainer.shared.resolve(GameStatusRepositoryProtocol.self)
        let dataDownloadRepository = DIContainer.shared.resolve(DataDownloadRepositoryProtocol.self)

        let vm = SelectMusicViewModel(
            playersRepository: playersRepository,
            answerRepository: answersRepository,
            gameStatusRepository: gameStatusRepository,
            dataDownloadRepository: dataDownloadRepository
        )
        let vc = SelectMusicViewController(selectMusicViewModel: vm)

        let guideVC = GuideViewController(type: .submitMusic) { [weak self] in
            guard let self else { return }
            navigationController.pushViewController(vc, animated: true)
            setupNavigationBar(for: vc)
        }
        navigationController.pushViewController(guideVC, animated: true)
    }

    private func navigateToHumming() {
        let gameStatusRepository = DIContainer.shared.resolve(GameStatusRepositoryProtocol.self)
        let playersRepository = DIContainer.shared.resolve(PlayersRepositoryProtocol.self)
        let answersRepository = DIContainer.shared.resolve(AnswersRepositoryProtocol.self)
        let recordsRepository = DIContainer.shared.resolve(RecordsRepositoryProtocol.self)

        let vm = HummingViewModel(
            gameStatusRepository: gameStatusRepository,
            playersRepository: playersRepository,
            answersRepository: answersRepository,
            recordsRepository: recordsRepository
        )
        let vc = HummingViewController(viewModel: vm)

        let guideVC = GuideViewController(type: .humming) { [weak self] in
            guard let self else { return }
            navigationController.pushViewController(vc, animated: true)
            setupNavigationBar(for: vc)
        }
        navigationController.pushViewController(guideVC, animated: true)
    }

    private func navigateToRehumming() {
        let gameStatusRepository = DIContainer.shared.resolve(GameStatusRepositoryProtocol.self)
        let playersRepository = DIContainer.shared.resolve(PlayersRepositoryProtocol.self)
        let recordsRepository = DIContainer.shared.resolve(RecordsRepositoryProtocol.self)

        let vm = RehummingViewModel(
            gameStatusRepository: gameStatusRepository,
            playersRepository: playersRepository,
            recordsRepository: recordsRepository
        )
        let vc = RehummingViewController(viewModel: vm)

        let guideVC = GuideViewController(type: .rehumming) { [weak self] in
            guard let self else { return }
            navigationController.pushViewController(vc, animated: true)
            setupNavigationBar(for: vc)
        }
        navigationController.pushViewController(guideVC, animated: true)
    }

    private func navigateToSubmitAnswer() {
        let gameStatusRepository = DIContainer.shared.resolve(GameStatusRepositoryProtocol.self)
        let playersRepository = DIContainer.shared.resolve(PlayersRepositoryProtocol.self)
        let recordsRepository = DIContainer.shared.resolve(RecordsRepositoryProtocol.self)
        let submitsRepository = DIContainer.shared.resolve(SubmitsRepositoryProtocol.self)
        let dataDownloadRepository = DIContainer.shared.resolve(DataDownloadRepositoryProtocol.self)

        let vm = SubmitAnswerViewModel(
            gameStatusRepository: gameStatusRepository,
            playersRepository: playersRepository,
            recordsRepository: recordsRepository,
            submitsRepository: submitsRepository,
            dataDownloadRepository: dataDownloadRepository
        )
        let vc = SubmitAnswerViewController(viewModel: vm)

        let guideVC = GuideViewController(type: .submitAnswer) { [weak self] in
            guard let self else { return }
            navigationController.pushViewController(vc, animated: true)
            setupNavigationBar(for: vc)
        }
        navigationController.pushViewController(guideVC, animated: true)
    }

    private func navigateToResult() {
        if navigationController.topViewController is HummingResultViewController {
            navigationController.topViewController?.title = setTitle()
            return
        }
        let hummingResultRepository = DIContainer.shared.resolve(HummingResultRepositoryProtocol.self)
        let gameStatusRepository = DIContainer.shared.resolve(GameStatusRepositoryProtocol.self)
        let playerRepository = DIContainer.shared.resolve(PlayersRepositoryProtocol.self)
        let roomActionRepository = DIContainer.shared.resolve(RoomActionRepositoryProtocol.self)
        let roomInfoRepository = DIContainer.shared.resolve(RoomInfoRepositoryProtocol.self)
        let dataDownloadRepository = DIContainer.shared.resolve(DataDownloadRepositoryProtocol.self)

        let vm = HummingResultViewModel(
            hummingResultRepository: hummingResultRepository,
            gameStatusRepository: gameStatusRepository,
            playerRepository: playerRepository,
            roomActionRepository: roomActionRepository,
            roomInfoRepository: roomInfoRepository,
            dataDownloadRepository: dataDownloadRepository
        )
        let vc = HummingResultViewController(viewModel: vm)

        let guideVC = GuideViewController(type: .result) { [weak self] in
            guard let self else { return }
            navigationController.pushViewController(vc, animated: true)
            setupNavigationBar(for: vc)
        }
        navigationController.pushViewController(guideVC, animated: true)
    }

    private func leaveRoom() {
        Task {
            do {
                _ = try await roomActionRepository.leaveRoom()
            } catch {
                ErrorHandler.handle(error)
            }
        }
    }
}

// MARK: - Alert

private extension GameNavigationController {
    func showNotPlayable() {
        let alert = SingleButtonAlertController(titleText: .notPlayable) { _ in
            self.navigationController.popToRootViewController(animated: true)
            self.navigationController.navigationBar.isHidden = true
        }
        navigationController.presentAlert(alert)
    }
}
