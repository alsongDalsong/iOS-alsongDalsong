import SwiftUI

final class SelectMusicViewController: UIViewController {
    private let progressBar = ProgressBar()
    private let submitButton = ASButton()
    private let submissionStatus = SubmissionStatusView()
    private let viewModel: SelectMusicViewModel
    private var selectMusicView = UIViewController()

    init(selectMusicViewModel: SelectMusicViewModel) {
        self.viewModel = selectMusicViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setAction()
        setupUI()
        setupLayout()
        bindToComponents()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        viewModel.cancelSubscriptions()
    }
    
    private func bindToComponents() {
        progressBar.bind(to: viewModel.$dueTime)
        submitButton.bind(to: viewModel.$musicData)
        submissionStatus.bind(to: viewModel.$submissionStatus)
    }
    
    private func setupUI() {
        view.backgroundColor = .asBackground
        submitButton.setConfiguration(text: String(localized: "선택 완료"), backgroundColor: .asLightRed, shadowColor: .buttonShadowOfRed)
        submitButton.setDisabledState()
        let musicView = SelectMusicView(viewModel: viewModel)
        selectMusicView = UIHostingController(rootView: musicView)
        
        view.addSubview(selectMusicView.view)
        view.addSubview(progressBar)
        view.addSubview(submitButton)
        view.addSubview(submissionStatus)
    }
    
    private func setupLayout() {
        let safeArea = view.safeAreaLayoutGuide
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        submissionStatus.translatesAutoresizingMaskIntoConstraints = false
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        selectMusicView.view.translatesAutoresizingMaskIntoConstraints = false
    
        NSLayoutConstraint.activate([
            progressBar.topAnchor.constraint(equalTo: safeArea.topAnchor),
            progressBar.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: .responsiveHeight(view, 16)),

            selectMusicView.view.topAnchor.constraint(equalTo: progressBar.bottomAnchor),
            selectMusicView.view.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            selectMusicView.view.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            selectMusicView.view.bottomAnchor.constraint(equalTo: submitButton.topAnchor, constant: .responsiveHeight(view, -20)),

            submissionStatus.topAnchor.constraint(equalTo: submitButton.topAnchor, constant: .responsiveHeight(view, -16)),
            submissionStatus.trailingAnchor.constraint(equalTo: submitButton.trailingAnchor, constant: .responsiveWidth(view, 16)),

            submitButton.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: .responsiveWidth(view, 24)),
            submitButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: .responsiveWidth(view, -24)),
            submitButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            submitButton.heightAnchor.constraint(equalToConstant: .responsiveHeight(view, 64)),
        ])
    }
    
    private func setAction() {
        submitButton.addAction(UIAction { [weak self] _ in
            self?.showSubmitMusicLoading()
        }, for: .touchUpInside)
        
        progressBar.setCompletionHandler { [weak self] in
            guard self?.viewModel.selectedMusic != nil else {
                self?.showSubmitRandomMusicLoading()
                return
            }
            self?.showSubmitMusicLoading()
        }
    }
    
    private func pickRandomMusic() async throws {
        try await viewModel.randomMusic()
    }
    
    private func submitMusic() async throws {
        viewModel.stopMusic()
        progressBar.cancelCompletion()
        try await viewModel.submitMusic()
        submitButton.setConfiguration(.submitted)
        submitButton.setDisabledState()
    }
}

// MARK: - Alert

extension SelectMusicViewController {
    private func showSubmitMusicLoading() {
        let alert = LoadingAlertController(
            progressText: .submitMusic,
            loadAction: { [weak self] in
                try await self?.submitMusic()
            },
            errorCompletion: { [weak self] error in
                self?.showFailSubmitMusic(error)
            })
        presentAlert(alert)
    }
    
    private func showSubmitRandomMusicLoading() {
        let alert = LoadingAlertController(
            progressText: .submitMusic,
            loadAction: { [weak self] in
                try await self?.pickRandomMusic()
                try await self?.submitMusic()
            },
            errorCompletion: { [weak self] error in
                self?.showFailSubmitMusic(error)
            })
        presentAlert(alert)
    }
    
    private func showFailSubmitMusic(_ error: Error) {
        let alert = SingleButtonAlertController(titleText: .error(error))
        presentAlert(alert)
    }
}
