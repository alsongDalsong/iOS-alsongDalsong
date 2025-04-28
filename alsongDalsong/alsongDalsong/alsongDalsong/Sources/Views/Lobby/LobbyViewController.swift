import Combine
import SwiftUI

final class LobbyViewController: UIViewController {
    private let roomNumberButton = ASButton()
    private let inviteButton = ASButton()
    private let startButton = ASButton()
    private lazy var lobbyUIHostingController = UIHostingController(rootView: LobbyView(viewModel: viewmodel))
    private let viewmodel: LobbyViewModel
    private var cancellables: Set<AnyCancellable> = []

    init(lobbyViewModel: LobbyViewModel) {
        viewmodel = lobbyViewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        lobbyUIHostingController.view.isHidden = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLayout()
        setAction()
        bindToComponents()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        lobbyUIHostingController.view.isHidden = true
    }

    private func bindToComponents() {
        viewmodel.$canBeginGame.combineLatest(viewmodel.$isHost)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] canBeginGame, isHost in
                if isHost {
                    if canBeginGame {
                        self?.startButton.setConfiguration(.startGame)
                        self?.startButton.isEnabled = true
                    }
                    else {
                        self?.startButton.setConfiguration(.needMorePlayers)
                        self?.startButton.setDisabledState()
                    }
                }
                else {
                    self?.startButton.setConfiguration(.startWaiting)
                    self?.startButton.setDisabledState()
                }
            }
            .store(in: &cancellables)

        viewmodel.$roomNumber
            .receive(on: DispatchQueue.main)
            .sink { [weak self] roomNumber in
                self?.roomNumberButton.setConfiguration(
                    text: "#" + roomNumber,
                    textStyle: .largeTitle,
                    backgroundColor: .roomNumberButton,
                    baseForegroundColor: .asForeground,
                    shadowColor: .buttonShadowWithLine,
                    shadowHeight: 4,
                    strokeColor: .buttonShadowWithLine,
                    strokeWidth: 3
                )
            }
            .store(in: &cancellables)
    }

    private func setupUI() {
        view.backgroundColor = .asBackground

        roomNumberButton.setConfiguration(
            text: "#" + viewmodel.roomNumber,
            textStyle: .largeTitle,
            backgroundColor: .roomNumberButton,
            baseForegroundColor: .asForeground,
            shadowColor: .buttonShadowWithLine,
            shadowHeight: .responsiveHeight(4),
            strokeColor: .buttonShadowWithLine,
            strokeWidth: .responsiveWidth(3)
        )

        inviteButton.setConfiguration(
            systemImageName: "square.and.arrow.up",
            imageSize: .responsiveWidth(24),
            text: nil,
            backgroundColor: .inviteButton,
            baseForegroundColor: .tintColor,
            shadowColor: .buttonShadowOfDefault,
            shadowHeight: .responsiveHeight(4)
        )

        startButton.setConfiguration(
            systemImageName: "play.fill",
            text: "시작하기",
            backgroundColor: .asLightRed,
            shadowColor: .buttonShadowOfRed
        )

        view.addSubview(lobbyUIHostingController.view)
        view.addSubview(roomNumberButton)
        view.addSubview(startButton)
        view.addSubview(inviteButton)
    }

    private func setAction() {
        roomNumberButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let roomNumber = viewmodel.roomNumber
            UIPasteboard.general.string = roomNumber
            roomNumberButton.animateConfirmation(temporaryText: "복사 됨!")
        }, for: .touchUpInside)

        inviteButton.addAction(UIAction { [weak self] _ in
            guard let roomNumber = self?.viewmodel.roomNumber else { return }
            if let url = URL(string: "alsongDalsong://invite/?roomnumber=\(roomNumber)") {
                let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self?.inviteButton
                self?.present(activityViewController, animated: true, completion: nil)
            }
        }, for: .touchUpInside)

        startButton.addAction(
            UIAction { [weak self] _ in
                guard let playerCount = self?.viewmodel.players.count else { return }
                playerCount < 3 ?
                    self?.showNeedMorePlayers() :
                    self?.showStartGameLoading()
            },
            for: .touchUpInside
        )
    }

    private func setupLayout() {
        let safeArea = view.safeAreaLayoutGuide
        roomNumberButton.translatesAutoresizingMaskIntoConstraints = false
        inviteButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.translatesAutoresizingMaskIntoConstraints = false
        lobbyUIHostingController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            lobbyUIHostingController.view.topAnchor.constraint(equalTo: safeArea.topAnchor),
            lobbyUIHostingController.view.bottomAnchor.constraint(equalTo: inviteButton.topAnchor, constant: .responsiveHeight(-20)),
            lobbyUIHostingController.view.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            lobbyUIHostingController.view.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),

            roomNumberButton.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: .responsiveWidth(24)),
            roomNumberButton.trailingAnchor.constraint(equalTo: inviteButton.leadingAnchor, constant: .responsiveWidth(-16)),
            roomNumberButton.bottomAnchor.constraint(equalTo: startButton.topAnchor, constant: .responsiveHeight(-24)),
            roomNumberButton.heightAnchor.constraint(equalToConstant: .responsiveHeight(80)),

            inviteButton.bottomAnchor.constraint(equalTo: startButton.topAnchor, constant: .responsiveHeight(-24)),
            inviteButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: .responsiveWidth(-24)),
            inviteButton.widthAnchor.constraint(equalToConstant: .responsiveWidth(84)),
            inviteButton.heightAnchor.constraint(equalToConstant: .responsiveHeight(80)),

            startButton.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: .responsiveWidth(24)),
            startButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: .responsiveWidth(-24)),
            startButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: .responsiveHeight(-16)),
            startButton.heightAnchor.constraint(equalToConstant: .responsiveHeight(64)),
        ])
    }

    private func gameStart() async throws {
        try await viewmodel.gameStart()
    }
}

// MARK: - Alert

extension LobbyViewController {
    func showStartGameLoading() {
        let alert = LoadingAlertController(
            progressText: .startGame,
            loadAction: { [weak self] in
                try await self?.gameStart()
            },
            errorCompletion: { [weak self] error in
                self?.showStartGameFailed(error)
            }
        )
        presentAlert(alert)
    }

    func showNeedMorePlayers() {
        let alert = DefaultAlertController(
            titleText: .needMorePlayer,
            primaryButtonText: .keep,
            secondaryButtonText: .cancel
        ) { [weak self] _ in
            self?.showStartGameLoading()
        }
        presentAlert(alert)
    }

    func showStartGameFailed(_ error: Error) {
        let alert = SingleButtonAlertController(titleText: .error(error))
        presentAlert(alert)
    }
}
