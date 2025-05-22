import UIKit

final class RehummingViewController: UIViewController {
    private let progressBar = ProgressBar()
    private let scrollView = UIScrollView()
    private let largeAudioPlayerView = LargeAudioPlayerView()
    private let hummingPanel = RecordingPanel()
    private let recordButton = ASButton()
    private let submitButton = ASButton()
    private let submissionStatus = SubmissionStatusView()
    private let buttonStack = UIStackView()
    private let viewModel: RehummingViewModel

    init(viewModel: RehummingViewModel) {
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
        largeAudioPlayerView.unbind()
        viewModel.cancelSubscriptions()
    }

    private func bindToComponents() {
        submissionStatus.bind(to: viewModel.$submissionStatus)
        progressBar.bind(to: viewModel.$dueTime)
        largeAudioPlayerView.bind(to: viewModel.$music)
        largeAudioPlayerView.bind(to: viewModel.$isRecording)
        hummingPanel.bind(to: viewModel.$isRecording)
        hummingPanel.onRecordingFinished = { [weak self] recordedData in
            self?.recordButton.setConfiguration(.reRecord)
            self?.viewModel.updateRecordedData(with: recordedData)
        }
        submitButton.bind(to: viewModel.$recordedData)
    }

    private func setupUI() {
        recordButton.setConfiguration(.startRecord)
        submitButton.setConfiguration(.submit)
        submitButton.setDisabledState()
        buttonStack.axis = .horizontal
        buttonStack.spacing = .responsiveWidth(16)
        buttonStack.addArrangedSubview(recordButton)
        buttonStack.addArrangedSubview(submitButton)
        scrollView.addSubview(largeAudioPlayerView)
        scrollView.addSubview(hummingPanel)
        view.backgroundColor = .asBackground
        view.addSubview(progressBar)
        view.addSubview(scrollView)
        view.addSubview(buttonStack)
        view.addSubview(submissionStatus)
    }

    private func setAction() {
        recordButton.addAction(UIAction { [weak self] _ in
            self?.recordButton.setConfiguration(.recording)
            self?.viewModel.startRecording()
        },
        for: .touchUpInside)

        submitButton.addAction(UIAction { [weak self] _ in
            self?.showSubmitHummingLoading()
        }, for: .touchUpInside)

        progressBar.setCompletionHandler { [weak self] in
            self?.showSubmitHummingLoading()
        }
    }

    private func setupLayout() {
        let safeArea = view.safeAreaLayoutGuide
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        largeAudioPlayerView.translatesAutoresizingMaskIntoConstraints = false
        hummingPanel.translatesAutoresizingMaskIntoConstraints = false
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
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: hummingPanel.bottomAnchor, constant: .responsiveHeight(20)),

            largeAudioPlayerView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: .responsiveHeight(20)),
            largeAudioPlayerView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: .responsiveWidth(20)),
            largeAudioPlayerView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: .responsiveWidth(-20)),

            hummingPanel.topAnchor.constraint(equalTo: largeAudioPlayerView.bottomAnchor),
            hummingPanel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: .responsiveWidth(20)),
            hummingPanel.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: .responsiveWidth(-20)),
            hummingPanel.heightAnchor.constraint(equalToConstant: .responsiveHeight(80)),

            submissionStatus.topAnchor.constraint(equalTo: buttonStack.topAnchor, constant: .responsiveHeight(-16)),
            submissionStatus.trailingAnchor.constraint(equalTo: buttonStack.trailingAnchor, constant: .responsiveWidth(16)),

            buttonStack.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: .responsiveWidth(24)),
            buttonStack.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: .responsiveWidth(-24)),
            buttonStack.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: .responsiveHeight(-16)),
            buttonStack.heightAnchor.constraint(greaterThanOrEqualToConstant: .responsiveHeight(64)),
        ])
    }

    private func submitHumming() async throws {
        viewModel.stopMusic()
        progressBar.cancelCompletion()
        try await viewModel.submitHumming()
        submitButton.setConfiguration(.submitted)
        submitButton.setDisabledState()
        recordButton.setDisabledState()
    }
}

// MARK: - Alert

extension RehummingViewController {
    private func showSubmitHummingLoading() {
        let alert = LoadingAlertController(
            progressText: .submitHumming,
            loadAction: { [weak self] in
                try await self?.submitHumming()
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
