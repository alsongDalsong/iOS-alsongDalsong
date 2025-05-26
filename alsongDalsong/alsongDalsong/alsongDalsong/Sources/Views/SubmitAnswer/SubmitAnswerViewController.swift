import SwiftUI

final class SubmitAnswerViewController: UIViewController {
    private let progressBar = ProgressBar()
    private let scrollView = UIScrollView()
    private let largeAudioPlayerView = LargeAudioPlayerView()
    private let selectAnswerButton = SelectAnswerButton()
    private let submitButton = ASButton()
    private let submissionStatus = SubmissionStatusView()
    private let buttonStack = UIStackView()
    private let viewModel: SubmitAnswerViewModel
    private var selectedAnswerView: UIHostingController<SelectAnswerView>?

    init(viewModel: SubmitAnswerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        setupUI()
        setupLayout()
        setAction()
        bindToComponents()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        selectAnswerButton.unbind()
        largeAudioPlayerView.unbind()
        viewModel.cancelSubscriptions()
    }

    private func bindToComponents() {
        submissionStatus.bind(to: viewModel.$submissionStatus)
        progressBar.bind(to: viewModel.$dueTime)
        largeAudioPlayerView.bind(to: viewModel.$music)
        selectAnswerButton.bind(to: viewModel.$selectedMusic)
        selectAnswerButton.bind(to: viewModel.$isSearching)
        selectAnswerButton.bind(to: viewModel.$isPlaying)
        submitButton.bind(to: viewModel.$musicData)
    }

    private func setupUI() {
        submitButton.setConfiguration(text: String(localized: "제출하기"), backgroundColor: .asLightRed, shadowColor: .buttonShadowOfRed)
        submitButton.setDisabledState()
        buttonStack.axis = .horizontal
        buttonStack.spacing = .responsiveWidth(16)
        buttonStack.addArrangedSubview(submitButton)
        view.backgroundColor = .asBackground
    }

    private func setupLayout() {
        let safeArea = view.safeAreaLayoutGuide
        view.addSubview(progressBar)
        view.addSubview(scrollView)
        view.addSubview(buttonStack)
        view.addSubview(submissionStatus)
        scrollView.addSubview(largeAudioPlayerView)
        scrollView.addSubview(selectAnswerButton)

        progressBar.translatesAutoresizingMaskIntoConstraints = false
        largeAudioPlayerView.translatesAutoresizingMaskIntoConstraints = false
        selectAnswerButton.translatesAutoresizingMaskIntoConstraints = false
        submissionStatus.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            progressBar.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: .responsiveHeight(8)),
            progressBar.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: .responsiveHeight(16)),

            scrollView.topAnchor.constraint(equalTo: progressBar.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: buttonStack.topAnchor),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: selectAnswerButton.bottomAnchor, constant: .responsiveHeight(20)),

            largeAudioPlayerView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: .responsiveHeight(20)),
            largeAudioPlayerView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: .responsiveWidth(20)),
            largeAudioPlayerView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: .responsiveWidth(-20)),

            selectAnswerButton.topAnchor.constraint(equalTo: largeAudioPlayerView.bottomAnchor),
            selectAnswerButton.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: .responsiveWidth(20)),
            selectAnswerButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: .responsiveWidth(-20)),
            selectAnswerButton.heightAnchor.constraint(equalToConstant: .responsiveHeight(80)),

            submissionStatus.topAnchor.constraint(equalTo: buttonStack.topAnchor, constant: .responsiveHeight(-16)),
            submissionStatus.trailingAnchor.constraint(equalTo: buttonStack.trailingAnchor, constant: .responsiveWidth(16)),

            buttonStack.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: .responsiveWidth(24)),
            buttonStack.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: .responsiveWidth(-24)),
            buttonStack.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: .responsiveHeight(-16)),
            buttonStack.heightAnchor.constraint(greaterThanOrEqualToConstant: .responsiveHeight(64)),
        ])
    }

    private func pickRandomMusic() async throws {
        try await viewModel.randomMusic()
    }

    private func submitAnswer() async throws {
        selectAnswerButton.unbind()
        largeAudioPlayerView.unbind()
        viewModel.stopMusic()
        progressBar.cancelCompletion()
        try await viewModel.submitAnswer()
        submitButton.setConfiguration(.submitted)
        submitButton.setDisabledState()
    }

    private func setAction() {
        selectAnswerButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            selectedAnswerView = UIHostingController(rootView: SelectAnswerView(viewModel: viewModel))
            if let sheet = selectedAnswerView?.sheetPresentationController {
                sheet.detents = [
                    .medium(),
                    .large(),
                ]
                sheet.prefersGrabberVisible = true
            }
            viewModel.stopMusic()
            guard let selectAnswerView = selectedAnswerView else { return }
            present(selectAnswerView, animated: true)
        },
        for: .touchUpInside)

        submitButton.addAction(
            UIAction { [weak self] _ in
                self?.showSubmitAnswerLoading()
            }, for: .touchUpInside
        )

        progressBar.setCompletionHandler { [weak self] in
            guard self?.viewModel.selectedMusic != nil else {
                self?.showSubmitRandomMusicLoading()
                return
            }
            self?.showSubmitAnswerLoading()
        }
    }
}

// MARK: - Alert

extension SubmitAnswerViewController {
    private func showSubmitAnswerLoading() {
        let alert = LoadingAlertController(
            progressText: .submitMusic,
            loadAction: { [weak self] in
                try await self?.submitAnswer()
            }
        ) { [weak self] error in
            self?.showFailSubmitMusic(error)
        }
        presentAlert(alert)
    }

    private func showSubmitRandomMusicLoading() {
        let alert = LoadingAlertController(
            progressText: .submitMusic,
            loadAction: { [weak self] in
                try await self?.pickRandomMusic()
                try await self?.submitAnswer()
            },
            errorCompletion: { [weak self] error in
                self?.showFailSubmitMusic(error)
            }
        )
        presentAlert(alert)
    }

    private func showFailSubmitMusic(_ error: Error) {
        let alert = SingleButtonAlertController(titleText: .error(error))
        presentAlert(alert)
    }
}
