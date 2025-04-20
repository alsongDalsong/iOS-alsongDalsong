import ASContainer
import ASRepositoryProtocol
import AVFoundation
import Combine
import UIKit

final class OnboardingViewController: UIViewController {
    private let titleLabel = UILabel()
    private let createRoomButton = ASButton()
    private let joinRoomButton = ASButton()
    private let avatarView = ASAvatarView()
    private let nickNamePanel = NicknamePanel()
    private let inviteCode: String
    private var viewModel: OnboardingViewModel?
    private var gameNavigationController: GameNavigationController?
    private var cancellables = Set<AnyCancellable>()
    private var shouldMoveKeyboard: Bool = false

    var avatarViewBottomConstraint: NSLayoutConstraint?

    init(viewModel: OnboardingViewModel, inviteCode: String) {
        self.viewModel = viewModel
        self.inviteCode = inviteCode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        inviteCode = ""
        viewModel = nil
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLayout()
        setAction()
        setupButton()
        hideKeyboard()
        bindViewModel()
        bindNicknamePanel()
        viewModel?.authorizeAppleMusic()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observeKeyboard()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
        NotificationCenter.default.removeObserver(self)
    }

    private func setupUI() {
        view.backgroundColor = .asBackground

        titleLabel.text = "알쏭달쏭"
        titleLabel.font = UIFont.font(.riaSans, ofSize: 32)
        titleLabel.textColor = .onboardingForeground

        for item in [titleLabel, nickNamePanel, avatarView, createRoomButton, joinRoomButton] {
            view.addSubview(item)
            item.translatesAutoresizingMaskIntoConstraints = false
        }

        if !inviteCode.isEmpty {
            createRoomButton.isHidden = true
        }
    }

    private func setupLayout() {
        avatarViewBottomConstraint = avatarView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 10)
        guard let avatarViewBottomConstraint else { return }
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),

            nickNamePanel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 70),
            nickNamePanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            nickNamePanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            nickNamePanel.heightAnchor.constraint(equalToConstant: 300),

            avatarView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            avatarView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            avatarViewBottomConstraint,
            avatarView.heightAnchor.constraint(equalToConstant: 510),

            createRoomButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            createRoomButton.widthAnchor.constraint(equalTo: joinRoomButton.widthAnchor),
            createRoomButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            createRoomButton.heightAnchor.constraint(equalToConstant: 64),

            joinRoomButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            joinRoomButton.leadingAnchor.constraint(equalTo: createRoomButton.trailingAnchor, constant: 16),
            joinRoomButton.heightAnchor.constraint(equalToConstant: 64),
            joinRoomButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    private func setAction() {
        createRoomButton.addAction(
            UIAction { [weak self] _ in
                guard self?.isMicrophoneAuthorized() ?? false else {
                    self?.showMicrophonePermissionAlert()
                    return
                }

                self?.showCreateRoomLoading()
            },
            for: .touchUpInside
        )

        joinRoomButton.addAction(
            UIAction { [weak self] _ in
                guard self?.isMicrophoneAuthorized() ?? false else {
                    self?.showMicrophonePermissionAlert()
                    return
                }

                guard let inviteCode = self?.inviteCode else { return }
                inviteCode.isEmpty ?
                    self?.showRoomNumerInputAlert() : self?.autoJoinRoom()
            },
            for: .touchUpInside
        )

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapAvatarView(_:)))
        avatarView.addGestureRecognizer(tapGestureRecognizer)
    }

    private func setupButton() {
        createRoomButton.setConfiguration(
            systemImageName: "",
            text: Constants.craeteButtonTitle,
            textStyle: .title3,
            backgroundColor: .asLightRed,
            cornerStyle: .large,
            shadowColor: .buttonShadowOfRed
        )
        joinRoomButton.setConfiguration(
            systemImageName: "",
            text: Constants.joinButtonTitle,
            textStyle: .title3,
            backgroundColor: .asLightSky,
            cornerStyle: .large,
            shadowColor: .buttonShadowOfBlue
        )
    }

    private func bindViewModel() {
        bind(viewModel?.$nickname) { [weak self] nickname in
            let isPlaceholder = nickname == ""
            self?.createRoomButton.isEnabled = !isPlaceholder
            self?.joinRoomButton.isEnabled = !isPlaceholder
        }

        bind(viewModel?.$avatarData) { [weak self] data in
            guard let self = self else { return }

            self.avatarViewBottomConstraint?.constant = 600
            UIView.animate(withDuration: 0.7, animations: {
                self.view.layoutIfNeeded()
            }, completion: { _ in
                self.avatarView.setImage(imageData: data)
                self.avatarViewBottomConstraint?.constant = 10
                UIView.animate(withDuration: 0.7, delay: 0.2, animations: {
                    self.view.layoutIfNeeded()
                }, completion: nil)
            })
        }

        bind(viewModel?.$buttonEnabled) { [weak self] enabled in
            self?.createRoomButton.isEnabled = enabled
            self?.joinRoomButton.isEnabled = enabled
        }
    }

    private func bindNicknamePanel() {
        bind(nickNamePanel.$text) { [weak self] text in
            guard let text = text else { return }
            self?.viewModel?.setNickname(with: text)
        }
    }

    private func navigateToLobby(with roomNumber: String) {
        let mainRepository: MainRepositoryProtocol = DIContainer.shared.resolve(MainRepositoryProtocol.self)
        mainRepository.connectRoom(roomNumber: roomNumber)
        let gameStateRepository = DIContainer.shared.resolve(GameStateRepositoryProtocol.self)
        let roomActionRepository = DIContainer.shared.resolve(RoomActionRepositoryProtocol.self)
        guard let navigationController else { return }

        gameNavigationController = GameNavigationController(
            navigationController: navigationController,
            gameStateRepository: gameStateRepository,
            roomActionRepository: roomActionRepository,
            roomNumber: roomNumber
        )

        gameNavigationController?.setConfiguration()
    }

    private func bind<T>(
        _ publisher: Published<T>.Publisher?,
        handler: @escaping (T) -> Void
    ) {
        publisher?
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: handler)
            .store(in: &cancellables)
    }

    private func setNicknameAndJoinRoom(with roomNumber: String) {
        setNickname()
        Task {
            do {
                let number = try await viewModel?.joinRoom(roomNumber: roomNumber)
                guard let number, !number.isEmpty else { return }
                navigateToLobby(with: number)
            } catch {
                showRoomFailedAlert(error)
            }
        }
    }

    private func autoJoinRoom() {
        setNicknameAndJoinRoom(with: inviteCode)
    }

    private func manualJoinRoom(with roomNumber: String) {
        setNicknameAndJoinRoom(with: roomNumber)
    }

    private func setNicknameAndCreateRoom() async throws {
        setNickname()
        let number = try await viewModel?.createRoom()
        guard let number else { return }
        navigateToLobby(with: number)
    }

    private func setNickname() {
        if var nickname = nickNamePanel.text {
            if nickname == "캐릭터와닉네임을설정하라" || nickname.trimmingCharacters(in: .whitespaces).isEmpty {
                nickname = NickNameGenerator.generate()
            }

            nickNamePanel.updateTextField(placeholder: nickname)
        }
    }

    private func isMicrophoneAuthorized() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)

        return status == .authorized
    }
}

extension OnboardingViewController {
    enum Constants {
        static let craeteButtonTitle = String(localized: "방 생성하기!")
        static let joinButtonTitle = String(localized: "방 참가하기!")
        static let logoImageName = "logo"
    }
}

// MARK: - Alert

extension OnboardingViewController {
    private func showRoomNumerInputAlert() {
        shouldMoveKeyboard = false
        let alert = InputAlertController(
            titleText: .joinRoom,
            textFieldPlaceholder: .roomNumber
        ) { [weak self] roomNumber in
            self?.manualJoinRoom(with: roomNumber)
            self?.shouldMoveKeyboard = true
        } secondaryButtonAction: {
            self.shouldMoveKeyboard = true
        }

        presentAlert(alert)
    }

    private func showRoomFailedAlert(_ error: Error) {
        let alert = SingleButtonAlertController(titleText: .error(error))
        presentAlert(alert)
    }

    private func showMicrophonePermissionAlert() {
        let alert = DefaultAlertController(titleText: .permissionDenied, primaryButtonText: .setting, secondaryButtonText: .cancel) { _ in
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString),
                  UIApplication.shared.canOpenURL(settingsURL) else { return }

            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        }

        presentAlert(alert)
    }

    private func showCreateRoomLoading() {
        let alert = LoadingAlertController(
            progressText: .joinRoom,
            loadAction: { [weak self] in
                try await self?.setNicknameAndCreateRoom()
            },
            errorCompletion: { [weak self] error in
                self?.showRoomFailedAlert(error)
            }
        )
        presentAlert(alert)
    }
}

// MARK: - KeyboardObserve

private extension OnboardingViewController {
    private func observeKeyboard() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    func hideKeyboard() {
        view.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(
                    OnboardingViewController.dismissKeyboard
                )
            )
        )
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc func appDidEnterBackground() {
        view.endEditing(true)
    }

    @objc func didTapAvatarView(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
        viewModel?.refreshAvatars()
    }
}
